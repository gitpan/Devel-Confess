use strict;
use warnings;
use Test::More tests => 3;
use Safe;
use Devel::Confess ();

{
  package Shared::Ex;
  use overload '""' => sub { $_[0]->{message} };
  sub foo {
    die @_;
  }
  sub bar {
    foo(@_);
  }
  sub new {
    my $class = shift;
    bless {@_}, $class;
  }
}

my $comp = Safe->new;
$comp->share_from('main', [
  '*Shared::Ex::'
]);
$comp->permit('entereval');
Devel::Confess->import;
$comp->reval('Shared::Ex::bar("string")');
Devel::Confess->unimport;
like $@, qr{
  \Astring\ at\ \S+\ line\ \d+\.[\r\n]+
  [\t]Shared::Ex::foo\(.*?\)\ called\ at\ .*\ line\ \d+[\r\n]+
  [\t]Shared::Ex::bar\(.*?\)\ called\ at\ .*\ line\ \d+[\r\n]+
}x, 'works in Safe compartment with string error';

Devel::Confess->import;
sub { sub {
  $comp->reval('Shared::Ex->new(message => "welp")->bar');
}->(2) }->(1);
Devel::Confess->unimport;

isa_ok $@, 'Shared::Ex';

like "$@", qr{
  \AShared::Ex=\S+\ at\ \S+\ line\ \d+\.[\r\n]+
  [\t]Shared::Ex::foo\(.*?\)\ called\ at\ .*\ line\ \d+[\r\n]+
  [\t]Shared::Ex::bar\(.*?\)\ called\ at\ .*\ line\ \d+[\r\n]+
}x, 'works in Safe compartment with exception object';
