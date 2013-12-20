package Stick::Role::Collection::HasFilters;
use Moose::Role;
use MooseX::Types::Moose qw(ArrayRef CodeRef);
use namespace::autoclean -also => [ qw(ArrayRef CodeRef is_ArrayRef) ];

# filters return true or false
# an item is in the collection only if *all* filters return true
# replace this with a boolean tree structure later on - MJD 20110816
has filters => (
  is => 'ro',
  isa => ArrayRef[CodeRef],
  default => sub { [] },
);

around items => sub {
  my ($orig, $self, @args) = @_;
  my $items = $self->$orig(@args);
  return $items unless @{$self->filters};
  return [ grep $self->_item_in_collection($_), @$items ];
};

sub _item_in_collection {
  my ($self, $item) = @_;
  my $filters = $self->filters;
  local $_ = $item;
  for my $f (@$filters) { $f->($_) || return }
  return 1;
}

1;

