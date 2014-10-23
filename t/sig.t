use strict;
use warnings;
use Test::More tests => 10;
my $tm_die; BEGIN { $tm_die = $SIG{__DIE__} }
use t::lib::capture;

use Devel::Confess ();

is $SIG{__DIE__}, $tm_die, 'not activated without import';
my $called;
sub CALLED { $called++ };
$SIG{__DIE__} = \&CALLED;
Devel::Confess->import;
isnt $SIG{__DIE__}, \&CALLED, 'import overwrites existing __DIE__ handler';
$called = 0;
eval { die };
is 0+$called, 1, 'calls outer __DIE__ handler';
Devel::Confess->unimport;
is $SIG{__DIE__}, \&CALLED, 'unimport restores __DIE__ handler';

sub IGNORE { $called++ }
sub DEFAULT { $called++ }
sub other::sub { $called++ }

$SIG{__DIE__} = 'IGNORE';
Devel::Confess->import;
$called = 0;
eval { die };
is 0+$called, 0, 'no dispatching to IGNORE';
Devel::Confess->unimport;

$SIG{__DIE__} = 'DEFAULT';
Devel::Confess->import;
$called = 0;
eval { die };
is 0+$called, 0, 'no dispatching to DEFAULT';
Devel::Confess->unimport;

$SIG{__DIE__} = 'CALLED';
Devel::Confess->import;
$called = 0;
eval { die };
is 0+$called, 1, 'dispatches by name';
Devel::Confess->unimport;

$SIG{__DIE__} = 'other::sub';
Devel::Confess->import;
$called = 0;
eval { die };
is 0+$called, 1, 'dispatches by name to package sub';
Devel::Confess->unimport;

is capture <<'END_CODE', <<'END_OUTPUT', 'trace still added when outer __DIE__ exists';
BEGIN { $SIG{__DIE__} = sub { 1 } }
use Devel::Confess;
package A;

sub f {
#line 1 test-block.pl
    die "Beware!";
}

sub g {
#line 2 test-block.pl
    f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE
Beware! at test-block.pl line 1.
	A::f() called at test-block.pl line 2
	A::g() called at test-block.pl line 3
END_OUTPUT

is capture <<'END_CODE', '', 'outer __WARN__ can silence warnings';
BEGIN { $SIG{__WARN__} = sub { } }
use Devel::Confess;
package A;

sub f {
#line 1 test-block.pl
    warn "Beware!";
}

sub g {
#line 2 test-block.pl
    f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE
