package PTest::File::DuplicateMethods;
use Moose;

use Stick::Publisher;
use Stick::Publisher::Publish;
use namespace::autoclean;

publish original => {} => sub {
  return 0;
};

publish original => {} => sub {
  return 1;
};

no Moose;
1;
