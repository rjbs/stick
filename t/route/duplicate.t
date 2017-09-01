use strict;
use warnings;
use Test::Deep qw(cmp_deeply any array_each bool ignore);
use Test::More;
use Test::Fatal;

use lib 't/lib';

use Scalar::Util qw(blessed);

subtest "duplicate method fails" => sub {
  my $exc = exception {
    require PTest::DuplicateMethods;
    my $test = PTest::DuplicateMethods->new(filename => 'foo')
  };

  ok($exc, "we got an exception on a duplicate method");

  like(
    $exc,
    qr{method '\w+' already exists in package '},
    "we get a reasonable error message"
  );

};


done_testing;
