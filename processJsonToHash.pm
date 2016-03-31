
use JSON;
sub processJsonToHash{
	open JSON, "$_[0]" or die "$_[0] : $!\n";
	my $whole_json_file='';
#	{
#		local $/;
#		$whole_json_file=<JSON>;
#	}
	while (my $line = <JSON>){
		$line=~s/(\r)|(\n)|(\t)//g; # must process line by line as opposed to slurp whole file, since perl can't process > 1GB long string ("Error: substitution loop" blahblah)
	    $whole_json_file .= $line;
	}
	close JSON;
	#$whole_json_file=~s/(\r)|(\n)|(\t)//g;
	my $tree = decode_json($whole_json_file);
	return $tree;
}

1;