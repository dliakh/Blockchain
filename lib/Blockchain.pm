=head1 NAME

Blockchain -- a set of modules to access Blockchain.info API in an object oriented way

=head1 DESCRIPTION

There are two "API" modules Blockchain::Wallet::API and Blockchain::ReceivePayment::API
which represent Blockchain.info's L<Blockchain Wallet API|https://www.blockchain.com/api/blockchain_wallet_api> and L<Payment Processing API|https://www.blockchain.com/api/api_receive> respectively.

=cut 

# This package is defined to only contain the version information
package Blockchain;
our $VERSION = v0.01;

=head2 Blockchain::Wallet::API::Role

A definition of "contract" for the module representing the Blockchain Wallet API

=cut

package Blockchain::Wallet::API::Role;
use Moose::Role;
requires qw/create createHDAccount getActiveHDAccounts getHDAccount getHDXpubs addresses getAddressBalance generateAddress archiveAddress unarchiveAddress/;

=head2 Blockchain::Wallet::API

An object representing the Blockchain Wallet API

=cut

package Blockchain::Wallet::API;
use Moose;
with 'Blockchain::Wallet::API::Role';
use Carp;
use URI;
use LWP;
use JSON;
use List::Util qw/any/;
has uri => (is => 'rw', isa => 'Str', default => 'http://localhost:3000', required => 1);
has ua => (is => 'rw', isa => 'LWP::UserAgent', default => sub { LWP::UserAgent->new });

=head3 create

The 'create' API endpoint
Create a new blockchain wallet

=cut

sub create {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path('/api/v2/create');
    $uri->query_form(%opts);
    my $req = HTTP::Request->new(GET => $uri);
    my $res = $self->ua->request($req);
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 createHDAccount

The API endpoint '/merchant/:guid/accounts/create'

=cut

sub createHDAccount {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/merchant/$opts{guid}/accounts/create");
    $uri->query_form( password => $opts{password} );
    my @definedValidOptionalOptions = grep { my $optionName = $_; any {$optionName eq $_} qw/label api_code/ } keys %opts;
    $uri->query_form( map { $_ => $opts{$_}} @definedValidOptionalOptions );
    my $req = HTTP::Request->new(GET => $uri);
    my $res = $self->ua->request($req);
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 getActiveHDAccounts

List active HD accounts
The API endpoint '/merchant/:guid/accounts'

=cut

sub getActiveHDAccounts {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/merchant/$opts{guid}/accounts");
    $uri->query_form(password => $opts{password});
    
    my $req = HTTP::Request->new(GET => $uri);
    my $res = $self->ua->request($req);
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 getHDAccount

Get single HD account
The API endpoint '/merchant/:guid/accounts/:xpub_or_index'

=cut

sub getHDAccount {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/merchant/$opts{guid}/accounts/@{[$opts{xpub} // $opts{index}]}");
    $uri->query_form(password => $opts{password});
    $uri->query_form(api_code => $opts{api_code})
        if exists $opts{api_code};
    my $req = HTTP::Request->new(GET => $uri);
    my $res = $self->ua->request($req);
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 getHDXpubs

List HD xpubs
The API endpoint '/merchant/:guid/accounts/xpubs'

=cut

sub getHDXpubs {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/merchant/$opts{guid}/accounts/xpubs");
    $uri->query_form(password => $opts{password});
    $uri->query_form(api_code => $opts{api_code})
        if exists $opts{api_code};
    my $res = $self->ua->req( HTTP::Request->new(GET => $uri) );
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 addresses

List addresses
The Blockchain 'list' API endpoint

=cut

sub addresses {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/merchant/$opts{guid}/list");
    $uri->query_form(password => $opts{password});
    my $res = $self->ua->request(HTTP::Request->new(GET => $uri));
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 getAddressBalance

Fetch the address balance
The Blockchain 'address_balance' API endpoint

=cut

sub getAddressBalance {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/merchant/$opts{guid}/address_balance");
    $uri->query_path(password => $opts{password}, address => $opts{address});
    my $res = $self->ua->request(HTTP::Request->new($uri));
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 generateAddress

Generate a new address
The Blockchain API 'new_address' endpoint

=cut

sub generateAddress {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/merchant/$opts{guid}/new_address");
    my %callArgs = (password => $opts{password});

    foreach my $optionalArgName (qw/second_password label/) {
        $callArgs{$optionalArgName} = $opts{$optionalArgName} 
            if exists $opts{$optionalArgName};
    }

    $uri->query_form( %callArgs );
    my $res = $self->ua->request(HTTP::Request->new(GET => $uri));
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 archiveAddress

Archive an address
The 'archive_address' Blockchain API endpoint

=cut

sub archiveAddress {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/merchant/$opts{guid}/archive_address");
    my %callArgs = (password => $opts{password}, address => $opts{address});
    $callArgs{second_password}=$opts{second_password}
        if exists $opts{second_password};
    $uri->query_form(%callArgs);
    my $res = $self->ua->get(HTTP::Request->new(GET => $uri));
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 unarchiveAddress

Unarchive an address
The 'unarchive_address' Blockchain API endpoint

=cut

sub unarchiveAddress {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/merchant/$opts{guid}/unarchive_address");
    my %callArgs = (password => $opts{password}, address => $opts{address});
    $callArgs{second_password} = $opts{second_password}
        if exists $opts{second_password};
    $uri->query_form(%callArgs);
    my $res = $self->ua->request(HTTP::Request->new($uri));
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head2 Blockchain::Wallet::Address

An object orinted representation of an address entity in the Blockchain.info Wallet API

=cut

package Blockchain::Wallet::Address;
use Moose;
has wallet => (is => 'rw', isa => 'Blockchain::Wallet');
has balance => (is => 'rw', isa => 'Num');
has address => (is => 'rw', isa => 'Str');
has label => (is => 'rw', isa => 'Str');
has total_received => (is => 'rw', isa => 'Num');

=head3 name archive

Archive the address

=cut

sub archive {
    my $self = shift;
    
    $self->wallet->archiveAddress(address => $self->address);
    return;
}

=head3 unarchive

Unarchive the address

=cut

sub unarchive {
    my $self = shift;

    $self->wallet->unarchiveAddress(address => $self->address);
    return;
}

=head2 Blockchain::Wallet

An object oriented representation of the Blockchain.info Wallet API

=cut

package Blockchain::Wallet;
use Moose;
has api => (is => 'rw', isa => 'Blockchain::Wallet::API', required => 1);
has guid => (is => 'rw', isa => 'Str', required => 1);
has label => (is => 'rw', isa => 'Str');
has address => (is => 'rw', isa => 'Str');
has password => (is => 'rw', isa => 'Str');

=head3 createHDAccount

Create a new account. Returns a L</Blockchain::Wallet::Account> object

=cut

sub createHDAccount {
    my $self = shift;
    my %opts = @_;

    my %delegateCallArgs = (
        guid => $self->guid,
        password => $self->password,
    );
    $delegateCallArgs{label} = $opts{label}
        if exists $opts{label};

    my $apiReturn = $self->api->createHDAccount(%delegateCallArgs);
    # the field names are different
    # from what is returned by another call
    # retrieving the accounts as the list
    # so we need to transform
    my %accountData = (
        archived => $apiReturn->{archived},
        extendedPrivateKey => $apiReturn->{xpriv},
        extendedPublicKey => $apiReturn->{xpub}
    );

    return Blockchain::Wallet::Account->new(
        wallet => $self,
        %accountData
    );
}

=head3 accounts

Return a reference to a list of L</Blockchain::Wallet::Account> objects representing the accounts for the corresponding wallet

=cut

sub accounts {
    my $self = shift;

    return [map {
        Blockchain::Wallet::Account->new(
            wallet => $self,
            %$_
        )
    }
        @{ $self->api->getActiveHDAccounts(
            guid => $self->guid,
            password => $self->password,
        ) }];
}

=head3 archiveAddress

Archive an address. Accepts one mandatory option -- an address to be archieved (as a plain text)

=cut

sub archiveAddress {
    my $self = shift;
    my %opts = @_;

    $self->api->archiveAddress(
        guid => $self->guid,
        password => $self->password,
        address => $opts{address}
    );
    return;
}

=head3 unarchiveAddress

Unarchive an address. Accepts one mandatory option -- an address to be archieved (as a plain text)

=cut

sub unarchiveAddress {
    my $self = shift;
    my %opts = @_;

    $self->api->unrachiveAddress(
        guid => $self->guid,
        password => $self->password,
        address => $opts{address}
    );
    return;
}

=head3 addresses

Return a reference to a list of L</Blockchain::Wallet::Address> objects
representing addresses available from the respective wallet

=cut

sub addresses {
    my $self = shift;
    
    return [map {Blockchain::Wallet::Address->new(
        wallet => $self,
        %$_
    )} @{$self->api->addresses(
        guid => $self->guid,
        password => $self->password
    )->{addresses}}];
}

=head2 Blockchain::Wallet::Account::Role

A "contract" for the Blockchain.info API representation

=cut

package Blockchain::Wallet::Account::Role;
use Moose::Role;
requires qw/index label archived extendedPublicKey extendedPrivateKey extendedPrivateKey receiveIndex lastUsedReceiveIndex receiveAddress/;

=head2 Blockchain::Wallet::Account

An object representing an account of the Blockchain.info's Wallet API

=cut

package Blockchain::Wallet::Account;
use Moose;
has wallet => (is => 'rw', isa => 'Blockchain::Wallet', required => 1);
has index => (is => 'rw', isa => 'Num');
has label => (is => 'rw', isa => 'Str');
has archived => (is => 'rw', isa => 'Bool');
has extendedPublicKey => (is => 'rw', isa => 'Str');
has extendedPrivateKey => (is => 'rw', isa => 'Str');
has receiveIndex => (is => 'rw', isa => 'Num');
has lastUsedReceiveIndex => (is => 'rw', isa => 'Maybe[Num]');
has receiveAddress => (is => 'rw', isa => 'Str');
with 'Blockchain::Wallet::Account::Role';

# every thing which didn't fit into the 'plain' object
# (which is dependent on something else in other words: API, database maybe, etc.)
package Blockchain::Wallet::Account::Decorator;
use Moose;
extends 'Blockchain::Wallet::Account';
# the following should probably reside in a separate unit
# anyway:
# (the following methods and fields are accesing the API(es))
# the following is needed for to update the address gap information
has receivePaymentApi => (is => 'rw', does => 'Blockchain::ReceivePayment::API::Role');
# the following is needed to update the balance information 
has walletApi => (is => 'rw', does => 'Blockchain::Wallet::API::Role');
# I also need the damn key
has key => (is => 'rw', isa => 'Str');
# the following are a 'proxy' methods / fields just to delegate the responsibolity of getting the results to other modules
# so that we don't care about the actual details
has gap => (is => 'rw', isa => 'Num', lazy => 1, builder => 'build_gap');
has balance => (is => 'rw', isa => 'Num', lazy => 1, builder => 'build_balance');
sub build_gap {
    my $self = shift;

    return $self->receivePaymentApi->checkgap( xpub => $self->extendedPublicKey, key => $self->key )->{gap};
}
sub build_balance {
    my $self = shift;

    return $self->walletApi->balance( guid => $self->wallet->guid, password => $self->wallet->password )->{balance};
}
# sub addresses {
#     my $self = shift;
# }

package Blockchain::ReceivePayment::API::Role;
use Moose::Role;
requires qw/receive checkgap balance_update block_notification/;

package Blockchain::ReceivePayment::API;
use Moose;
with 'Blockchain::ReceivePayment::API::Role';
use Carp;
use LWP;
use URI;
use URI::Encode qw/uri_encode/;
use JSON;
has uri => (is => 'rw', isa => 'Str', required => 1, default => 'https://api.blockchain.info');
has key => (is => 'rw', isa => 'Str', required => 1);
has ua => (is => 'rw', isa => 'LWP::UserAgent', required => 1, default => sub {LWP::UserAgent->new});

=head3 receive

Generate a receiving address, set up a callback to be called when the address recieves a payment

=cut

sub receive {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/v2/receive");
    $opts{key} = $self->key unless exists $opts{key};
    my %encodedOpts = map {  $_ => uri_encode($opts{$_}) }
        keys %opts;
    $uri->query_form(%encodedOpts);

    my $res = $self->ua->request(HTTP::Request->new(GET => $uri));
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 balance_update

Monitor addresses for received and spent payments

=cut

sub balance_update {
    my $self = shift;
    my %opts = @_;

    my $uri => URI->new($self->uri);
    $uri->path("/v2/receive/balance_update");
    $opts{key} = $self->key unless exists $opts{key};
    $uri->query_form(%opts);

    my $res = $self->ua->request(HTTP::Request->new(GET => $uri));
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 block_notification

Request callbacks when a new block of a specified height and confirmation number is added to the blockchain

=cut

sub block_notification {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/v2/receive/block_notification");
    $opts{key} = $self->key unless exists $opts{key};
    $uri->query_form(%opts);
    
    my $res = $self->ua->request(HTTP::Request->new(GET => $uri));
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}

=head3 checkgap

Check the index gap between last address paid to and the last address generated

=cut

sub checkgap {
    my $self = shift;
    my %opts = @_;

    my $uri = URI->new($self->uri);
    $uri->path("/v2/receive/checkgap");
    $opts{key} = $self->key unless exists $opts{key};
    $uri->query_form(%opts);
    my $res = $self->ua->request(HTTP::Request->new(GET => $uri));
    croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res)
        unless $res->is_success;
    return decode_json($res->content);
}
package Blockchain::API::Exception;
use Moose;
use JSON;
has code => (is => 'rw', isa => 'Num', default => 0);
has status_line => (is => 'rw', isa => 'Str', default => ''); # the HTTP status line
has content => (is => 'rw', isa => 'Str', default => '');
has _responseData => (is => 'rw', isa => 'Maybe[HashRef]', builder => '_build_responseData');
use overload '""' => sub { $_[0]->toString };
sub toString {
    my $self = shift;

    return join(' ', grep {defined && length} $self->status_line, $self->content);
}
sub message { @_ && ref $_[0] eq 'HASH' ? $_[0]->_responseData->{message} : undef }
sub description { @_ && ref $_[0] eq 'HASH' ? $_[0]->_responseData->{content} : undef }
sub _build_responseData {
    my $self = shift;

    return unless defined $self->content && length $self->content;
    return decode_json($self->content);
}
package Blockchain::API::Exception::Factory;
use JSON;
my %definedTypes = (
    400 => {
        "Problem with xpub" => {
            "Gap between last used address and next address too large. This might make funds inaccessible." => 'Blockchain::API::Exception::Gap'
        },
        "xpub not found" => {
            "" => 'Blockchain::API::Exception::Xpub::NotFound'
        }
    }
);
sub getFromHTTPResponse {
    my $class = shift;
    my ($response) = @_;

    my $responseData = decode_json($response->content);

    my $exceptionClass = $definedTypes{$response->code}->{$responseData->{message}}->{$responseData->{description} // ''}
        // 'Blockchain::API::Exception';
    return $exceptionClass->new(
        status_line => $response->status_line // '',
        code => $response->code // '',
        content => $response->content // ''
    );
}
package Blockchain::API::Exception::Gap;
use Moose;
extends 'Blockchain::API::Exception';
package Blockchain::API::Exception::Xpub::NotFound;
use Moose;
extends 'Blockchain::API::Exception';
package Blockchain;
use constant DEFAULT_GAP_LIMIT => 20;
package Blockchain::ExhangeRate::API;
use Moose;
use LWP;
use URI;
use Carp;
use constant DEFAULT_REVERSE_EXCHANGE_SUM => 100000; # the number of foreign currency units to exchange for calculating the reverse exchange rate
has reverseExchangeSum => (is => 'rw', isa => 'Num', required => 1, default => DEFAULT_REVERSE_EXCHANGE_SUM);
has currency => (is => 'rw', isa => 'Str');
# convert to btc: this method is directly supported by the api
sub tobtc {
		my $self = shift;
		my %options = @_;

		croak 'Please specify the value to convert via the value option' unless defined $options{value};
		my $currency = $options{currency} // $self->currency;
		croak 'Please specify currency either via the options to the btc call or via a currency accessor method. Probably it was either not specified or the value was undefined'
			unless defined $currency;
		my $uri = URI->new('https://blockchain.info/tobtc');
		$uri->query_path( currency => $currency, value => $options{value} );
		my $res = LWP::UserAgent->new->request( HTTP::Request->new(GET => $uri) );
		croak Blockchain::API::Exception::Factory->getFromHTTPResponse($res) unless $res->is_success;
		return $res->content;
}
sub frombtc {
		my $self = shift;
		my %options = @_;

		my $currency = $options{currency} // $self->currency;

		my $t = $self->tobtc(value => $self->reverseExchangeSum, currency => $currency);
		return $options{value} * $self->reverseExchangeSum / $t;
		# TODO: check the sum back converts to the same value
}
1;
