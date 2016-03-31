# quickTrackHub
quickTrackHub.pl generates a UCSC Genome Track Hub based on a list of UCSC-compatible genome data files and a JSON Track Definition File (TDF). An example of a TDF is included in this repository (`trackHubDefinition.json`).

## Usage
  Edit `trackHubDefinition.json` according to your needs, then run the following command from within a web-accessible directory, in which the Track Hub will be created:
  
  `quickTrackHub.pl trackHubDefinition.json`


## Dependencies:

### Standard CPAN modules
  
    File::Basename
    JSON
    
### Custom module 
(provided, must be in same directory as quickTrackHub.pl):
  
    processJsonToHash
    
