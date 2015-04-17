package EnsEMBL::Web::ViewConfig::Gene::Compara_Alignments;

use previous qw(init);

sub init {
  my $self = shift;
  $self->PREV::init;
  $self->set_defaults({
    line_numbering => 'slice',
    region_change_display => 'yes',
    title_display => 'yes',
  });
}

1;
