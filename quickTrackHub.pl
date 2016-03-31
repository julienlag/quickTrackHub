#!/usr/bin/env perl

###############################################################
## Author: Julien Lagarde, CRG. Contact: julienlag@gmail.com ##
###############################################################
use FindBin; # find present script
use lib "$FindBin::Bin"; # include script's directory (where processJsonToHash.pm is)
use strict;
use warnings;
use File::Basename;
use JSON;
use processJsonToHash;
$|=1;

my $trackHubDefJson=$ARGV[0];

die "No track definition JSON file provided. Cannot continue.\n" unless $trackHubDefJson;

my $trackDbDef = processJsonToHash($trackHubDefJson);

my $dataFileList=$$trackDbDef{'dataFilesList'}."/";
my $baseUrl=$$trackDbDef{'webPublicDir'}."/";

open FILES, "$dataFileList" or die $!;

my %fileAttributes=();

#we need to get the list of genomes, as there will be one trackDb.txt file per genome
my %genomes=();
my $genomeField=${$$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}}{'genome'};

while (<FILES>){
  chomp;
  my $file=$_;
  my($filename, $dir, $suffix) = fileparse($file, qr/\.[^.]*/);
  $suffix=~s/\.//;
  @{$fileAttributes{$file}}=split($$trackDbDef{'dataFileNameParsingInstructions'}{'fieldSeparator'}, $filename);
  push(@{$fileAttributes{$file}}, $suffix); # put file extension in last array element
  $genomes{${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{'genome'} ]}=1;
}

# output "hub.txt":
open O, ">hub.txt" or die $!;
print O "hub $$trackDbDef{'track'}
genomesFile genomes.txt
email $$trackDbDef{'trackHubAssociatedEmail'}
";
print O "shortLabel ".assignLabel($trackDbDef, 'shortLabel')."\n";
print O "longLabel ".assignLabel($trackDbDef, 'longLabel')."\n";

close O;

# output "genomes.txt":
open O, ">genomes.txt" or die $!;
foreach my $genome (keys %genomes){
  print O "genome $genome
trackDb $genome/trackDb.txt

";
}

#Now output one trackDb.txt per genome:

#list of valid settings for a track, with their priorities (e.g. 'track' must be written first)
my %stanzaSettingsPriority=(
                            'track' => 1,
                            'type' => 2,
                            'parent' => 2,
                            'bigDataUrl' => 2,
                            'shortLabel' => 2,
                            'longLabel' => 3,
                            'visibility' => 2,
                            'color' => 2,
                            'priority' => 2,
                            'itemRgb' => 2,
                            'colorByStrand' => 2,
                            'searchIndex' => 2,
                            'autoScale' => 2,
                            'maxHeightPixels' => 2,
                            'alwaysZero' => 2,
                            'bamColorMode' => 2,
                            'dragAndDrop' => 2
                    );

my %compositeDimensionToSubGroup=(
                         'x' => 1,
                         'y' => 2,
                         'a' => 3
                         );
my %fileExtToType=(
                   'bw' => 'bigWig'
                   );

my %filesInOutputHub=(); # to check that all input datafiles are in the output hub

foreach my $genome (keys %genomes){
  `mkdir -p $genome`;
  open O, ">$genome/trackDb.txt" or die $!;
  foreach my $superTrack (@{$$trackDbDef{'superTracks'}}){
    #first output standard settings
    foreach my $setting ( sort { $stanzaSettingsPriority{$a} <=> $stanzaSettingsPriority{$b} } keys(%stanzaSettingsPriority)){
       #mandatory settings
       if($setting eq 'track'){ # precede with \n to separate stanzas
        if(exists  $$superTrack{$setting}){
          print O "\n$setting $$superTrack{$setting}\n";
          unless (exists $$superTrack{'compositeDimensions'}){
            print O "superTrack on show\n";
          }
        }
        else{
          die "Mandatory 'track' property absent, cannot continue.\n";
        }
       }
       elsif($setting eq 'shortLabel' || $setting eq 'longLabel'){
         print O "$setting ".assignLabel($superTrack, $setting)."\n";
       }
       #non-mandatory settings
       elsif (exists $$superTrack{$setting}){
         print O "$setting $$superTrack{$setting}\n"; #must be printed first
       }

      }
      #now process other settings
      if(exists $$superTrack{'compositeDimensions'}){
        print O "compositeTrack on\n";
        foreach my $dimension (sort keys %{$$superTrack{'compositeDimensions'}}){
          #write "gTag" and "gTitle" for each subGroup/dimension
          print O "subGroup".$compositeDimensionToSubGroup{$dimension}." ".join("",@{${$$superTrack{'compositeDimensions'}}{$dimension}})." ".join("-",@{${$$superTrack{'compositeDimensions'}}{$dimension}});
          #write list of "mTag1a=mTitle1a"s:
          # make list of possible values by looping over all file attributes of files with matching "fileNameMatch" attribute(s)
          my %mTags=();
          #my %mTitles=();
          foreach my $file (keys %fileAttributes){
            my $fileMatchBool=0;
            foreach my $filePattern (keys %{$$superTrack{'fileNameMatch'}}){
              if(${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{$filePattern} ] eq ${$$superTrack{'fileNameMatch'}}{$filePattern}){
                $fileMatchBool=1;
              }
              else{ #at least one of the search pattern doesn't match, so skip the file
                $fileMatchBool=0;
                last;
              }
            }
            if($fileMatchBool == 1){ # file matches all filename patterns
              my $combinedAttrs=join("",@{${$$superTrack{'compositeDimensions'}}{$dimension}});
              my @combinedmTags=();
              foreach my $attr (@{${$$superTrack{'compositeDimensions'}}{$dimension}}){
                if (defined (${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{$attr} ])){
                  my $value=${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{$attr} ];
                  push(@combinedmTags, $value);

                }
              }
              $mTags{$combinedAttrs}{join("",@combinedmTags)}=1;
            }

          }
          foreach my $combinedAttrs (keys %mTags){
            foreach my $combinedmTag (keys %{$mTags{$combinedAttrs}}){
              print O " $combinedmTag=$combinedmTag "
            }
          }
           print O "\n";
        }
        print O "dimensions";
        foreach my $dimension (sort keys %{$$superTrack{'compositeDimensions'}}){
          print O " dim".uc($dimension)."=".join("", @{${$$superTrack{'compositeDimensions'}}{$dimension}});
        }
        print O "\n";
      }
      #now process corresponding files
      foreach my $file (keys %fileAttributes){
        my $fileMatchBool=0;
        foreach my $filePattern (keys %{$$superTrack{'fileNameMatch'}}){
          if(${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{$filePattern} ] eq ${$$superTrack{'fileNameMatch'}}{$filePattern}){
                $fileMatchBool=1;
          }
          else{ #at least one of the search pattern doesn't match, so skip the file
            $fileMatchBool=0;
            last;
          }
        }
        if($fileMatchBool == 1){ # file matches all filename patterns
          $filesInOutputHub{$file}=1;
          print O "\ntrack ".join ("", @{$fileAttributes{$file}})."
parent ".$$superTrack{'track'}."
bigDataUrl ".$baseUrl."$file
shortLabel ".substr(join (" ", @{$fileAttributes{$file}}), 0, 13)."...
longLabel ".join (", ", @{$fileAttributes{$file}})."
#viewUi on
";
          my $type;
          if(exists $fileExtToType{ ${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{'fileExtension'} ] }){
            $type=$fileExtToType{ ${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{'fileExtension'} ] };
          }
          else{
            $type=${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{'fileExtension'} ];
          }
          print O "type $type
";
        #compute subgroups
          if(exists $$superTrack{'compositeDimensions'}){
            print O "subGroups ";
            foreach my $dimension (sort keys %{$$superTrack{'compositeDimensions'}}){
              my $combinedAttrs=join("",@{${$$superTrack{'compositeDimensions'}}{$dimension}});
              my @combinedmTags=();
              foreach my $attr (@{${$$superTrack{'compositeDimensions'}}{$dimension}}){
                if (defined (${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{$attr} ])){
                  my $value=${$fileAttributes{$file}}[ $$trackDbDef{'dataFileNameParsingInstructions'}{'fields'}{$attr} ];
                  push(@combinedmTags, $value);
                }
              }
              print O join("",@{${$$superTrack{'compositeDimensions'}}{$dimension}})."=".join("",@combinedmTags)." ";
            }
            print O "\n";
          }
        }
      }
    }
  close O;
}

my @absentFilesinHub=();
foreach my $inFile (keys %fileAttributes){
    unless (exists $filesInOutputHub{$inFile}){
      push (@absentFilesinHub, $inFile)
  }
}
if($#absentFilesinHub>=0){
  print STDERR "WARNING: The following data files are NOT in the output track hub. Most probably their file name does not match what is required in the track definition file:\n".join("\n", @absentFilesinHub)."\n";
}

print STDERR "Track hub done.\n";

my $hubUrl=$baseUrl."hub.txt";

print STDERR "
SUMMARY:

 Track hub URL: ".$hubUrl."
 Direct browser URL(s) (one per genome assembly):\n";
foreach my $genome (keys %genomes){
  print STDERR "  http://genome.ucsc.edu/cgi-bin/hgTracks?db=".$genome."&hubUrl=$hubUrl\n"
}
print STDERR "\nRun 'hubCheck ".$hubUrl."' before loading the hub into the UCSC browser.\n";

sub assignLabel{
  #assign longLabel or shortLabel to a given track. If absent from the input JSON object, these attributes are assigned the value of the track's 'track' attribute
  #returns label
  my $label;
  my $inputStructure=$_[0];
  my $labelType=$_[1];
  if(exists $$inputStructure{$labelType}){
   $label=$$inputStructure{$labelType}
  }
  else{
    $label=$$inputStructure{'track'}
  }
  return $label;
}