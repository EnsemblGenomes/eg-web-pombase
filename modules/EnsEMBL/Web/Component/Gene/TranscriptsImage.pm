package EnsEMBL::Web::Component::Gene::TranscriptsImage;

use strict;
use Data::Dumper;
use base qw(EnsEMBL::Web::Component::Gene);

sub _init { 
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub caption {
  return 'Transcripts';
}

sub content {
  my $self   = shift;
  my $object = $self->object;
  my $gene   = $object->Obj;
  my $threshold = 20000;
  
  # my $gene_slice = $gene->feature_Slice->expand(10e3, 10e3);
  my $gene_slice;
  my $object_slice = $gene->feature_Slice;

      if ($object_slice->end >= $object_slice->start)  {

          my $c = int($object_slice->centrepoint);
          my $s = ($c - $threshold/2) + 1;
          $s = 1 if $s < 1;
          my $e = $s + $threshold - 1;

          if ($e > $object_slice->seq_region_length) {
              $e = $object_slice->seq_region_length;
              $s = $e - $threshold - 1;
          }

        $gene_slice = $object->database('core')->get_SliceAdaptor->fetch_by_region(
            $object_slice->coord_system_name, $object_slice->seq_region_name, $s, $e, 1
                                                                              );

      } else {

          my $c = int($object_slice->centrepoint);
          my $s = ($c - $threshold/2) + 1;
          if($s < 0) {
              $s = $object_slice->seq_region_length + $s;
          }
          $s = 1 if $s < 1;
          my $e = $s + $threshold - 1;

          if ($e > $object_slice->seq_region_length) {
              $e = $e - $object_slice->seq_region_length;
          }

        $gene_slice = $object->database('core')->get_SliceAdaptor->fetch_by_region(
            $object_slice->coord_system_name, $object_slice->seq_region_name, $s, $e, 1
                                                                              );
      }

     # $gene_slice = $gene_slice->invert if $object->seq_region_strand < 0;
     
  # Get the web_image_config
  my $image_config = $object->get_imageconfig('gene_summary');
  
  $image_config->set_parameters({
    container_width => $gene_slice->length,
    image_width     => $object->param('i_width') || $self->image_width || 800,
    slice_number    => '1|1',
  });
  
  $self->_attach_das($image_config);

  my $key  = $image_config->get_track_key('transcript', $object);
  my $node = $image_config->get_node(lc $key);
  
  $node->set('display', 'transcript_label') if $node && $node->get('display') eq 'off';
  
  #my $hub     = new EnsEMBL::Web::Hub;
  #my $ga  = $hub->get_adaptor('get_GeneAdaptor');
  #my @genes_from_slice = @{ $ga->fetch_all_by_Slice($gene_slice) };
  #warn (Dumper(@genes_from_slice));
  #warn (Dumper($image_config));
  #warn $gene->start . "\t" . $gene->end;
  
  my $image = $self->new_image($gene_slice, $image_config, [ $gene->stable_id ]);
  #warn (Dumper($image));
  return if $self->_export_image($image);
  
  $image->imagemap         = 'yes';
  $image->{'panel_number'} = 'top';
  $image->set_button('drag', 'title' => 'Drag to select region');
  
  return $image->render . $self->_info(
    'Configuring the display',
    '<p>Tip: use the "<strong>Configure this page</strong>" link on the left to show additional data in this region.</p>'
  );
}

1;
