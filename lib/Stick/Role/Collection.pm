package Stick::Role::Collection;
# ABSTRACT: A routable collection of objects
use strict;
use warnings;

use Carp 'confess';
use List::Util qw(min);
use MooseX::Role::Parameterized;
use MooseX::Types::Moose qw(Any ArrayRef Maybe Object Str Undef);
use Stick::Types qw(PositiveInt);
use Stick::Util qw(ppack);
use POSIX qw(ceil);
use Scalar::Util qw(blessed);
use namespace::autoclean -also => [ qw(Any ArrayRef Maybe is_Maybe Object Str is_Str Undef PositiveInt is_PositiveInt) ];

require Stick::Publisher;
use Stick::Publisher::Publish;

use namespace::autoclean;

# name of this kind of collection, typically something like "banks"
parameter collection_name => (
  is => 'ro',
  isa => Str,
  required => 1,
);

# name of the owner method that retrieves an array of items
parameter item_array => (
  is => 'ro',
  isa => Str,
  required => 1,
);

role {
  my ($p, %args) = @_;

  Stick::Publisher->import({ into => $args{operating_on}->name });
  sub publish;

  require Stick::Role::Routable::AutoInstance;

  BEGIN {
    require Carp;
    Carp->import(qw(carp confess croak));
  }

  my $collection_name = $p->collection_name;
  my $item_array      = $p->item_array;

  has collection_name => (
    isa => Str,
    is => 'ro',
    default => sub { $collection_name },
  );

  has owner => (
    isa => Object,
    is => 'ro',
    required => 1,
  );

  has item_array => (
    isa => Str,
    is => 'ro',
    default => $item_array,
  );

  method _subroute => sub {
    my ($self, @args) = @_;
    confess "Can't route collection class, instances only"
      unless blessed($self);
    $self->_instance_subroute(@args);
  };

  method _extra_instance_subroute => sub {
    my ($self, $path) = @_;

    return $self unless @$path;

    my ($first, $second) = @$path;

    if ($first eq "guid") {
      splice @$path, 0, 2;
      return $self->find_by_guid({guid => $second});
    } elsif ($first eq "xid") {
      splice @$path, 0, 2;
      return $self->find_by_xid({xid => $second});
    } elsif ($first eq "active") {
      splice @$path, 0, 2;
      return $self->find_active_by_xid({xid => $second});
    } elsif ($first eq "last") {
      splice @$path, 0, 1;
      return $self->last;
    } elsif ($first eq "first") {
      splice @$path, 0, 1;
      return $self->first;
    } else {
      return;
    }
  };

  with (qw(Stick::Role::PublicResource
           Stick::Role::Routable
           Stick::Role::Routable::AutoInstance
           Stick::Role::PublicResource::GetSelf
        ));

  method items => sub {
    my ($self) = @_;
    my $item_array = $self->item_array;
    return $self->owner->$item_array;
  };

  publish all => { } => sub {
    my ($self) = @_;
    return @{$self->items};
  };

  publish count => { } => sub {
    my ($self) = @_;
    return scalar @{$self->items};
  };

  method single => sub {
    my ($self, $msg) = @_;
    my (@items) = $self->all;
    confess $msg
      // "Found multiple objects in collection '$collection_name', expected at most one"
        if @items > 1;
    return $items[0];
  };

  publish find_by_guid => { guid => Str } => sub {
    my ($self, $arg) = @_;
    my $guid = $arg->{guid};
    return $self->filter(sub { $_->guid eq $guid })
      ->single("Found multiple objects in collection '$collection_name' with guid $guid");
  };

  publish find_by_xid => { xid => Str } => sub {
    my ($self, $arg) = @_;
    my $xid = $arg->{xid};
    return $self->filter(sub { $_->xid eq $xid })
      ->single("Found multiple objects in collection '$collection_name' with xid $xid");
 };

  publish find_active_by_xid => { xid => Str } => sub {
    my ($self, $arg) = @_;
    my $xid = $arg->{xid};
    return $self->filter(sub { $_->xid eq $xid && $_->is_active })
      ->single("Found multiple active objects in collection '$collection_name' with xid $xid");
 };

  method STICK_PACK => sub {
    my ($self) = @_;

    return {
      what   => $collection_name,
      owner  => $self->owner->guid, # Compose in Moonpig::Role::Collection
      items  => [ map {; ppack($_) } $self->all ] }; # recurse?
  }
};

1;
