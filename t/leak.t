use strict;
use warnings;
use Scalar::Util;
use Test::More
  defined &Scalar::Util::weaken ? (tests => 3)
    : (skip_all => "Can't prevent leaks without Scalar::Util::weaken");

use Devel::Confess;

my $gone = 0;
{
  package MyException;
  sub new {
    bless {}, __PACKAGE__;
  }
  sub throw {
    die __PACKAGE__->new;
  }
  sub DESTROY {
    $gone++;
  }
}

eval {
  MyException->throw;
};
my $class = ref $@;
is $gone, 0, "exception not destroyed when captured";
undef $@;
is $gone, 1, "exception destroyed after \$@ cleared";

ok !UNIVERSAL::can($class, 'DESTROY'), "temp packages don't leak";

