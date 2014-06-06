package EnsEMBL::Web::ViewConfig::Location::Compara_Alignments;

use previous qw(init);

sub init {
  my $self = shift;
  $self->PREV::init;
  $self->set_defaults({
    region_change_display => 'yes',
    title_display => 'yes',
  });
}

1;
