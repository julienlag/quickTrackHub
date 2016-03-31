# quickTrackHub
`quickTrackHub.pl` generates a [UCSC Genome Track Hub](http://genome.cse.ucsc.edu/goldenPath/help/hgTrackHubHelp.html) based on a list of UCSC-compatible genome data files and a JSON Track Hub Definition File (THDF). The list of data files to include must be specified in a text file, one data file path per line. The path to this list is specified in the `dataFilesList` JSON property of the THDF.
An example of a THDF is included in this repository (`trackHubDefinition.json`).

## Usage
Edit `trackHubDefinition.json` according to your needs, the following properties in particular:
  
  - `trackHubAssociatedEmail`: your email
  
  - `webPublicDir`: the HTTP/FTP address of your data directory where the Hub will be output
  
  - `dataFilesList`: the local path to the list of data files (one per line) to include in the hub
  
Then run the following command from within a web-accessible directory, in which the Track Hub will be created:

```
quickTrackHub.pl trackHubDefinition.json
```


## Dependencies:

### Standard CPAN modules
  
    File::Basename
    JSON
    FindBin
    
### Custom module 
(provided, must be in same directory as `quickTrackHub.pl`):
  
    processJsonToHash
    
