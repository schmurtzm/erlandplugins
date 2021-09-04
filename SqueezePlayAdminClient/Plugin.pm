# 				File Server Client plugin 
#
#    Copyright (c) 2010 Erland Isaksson (erland_i@hotmail.com)
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package Plugins::SqueezePlayAdminClient::Plugin;

use strict;

use base qw(Slim::Plugin::Base);

use Slim::Utils::Prefs;
use Slim::Utils::Misc;
use Slim::Utils::Strings qw(string);
use Slim::Utils::Log;
use File::Spec::Functions qw(:ALL);
use FindBin qw($Bin);
use MIME::Base64::Perl;
use Data::Dumper;

my @pluginDirs = ();
our $PLUGINVERSION =  undef;

my $serverPrefs = preferences('server');
my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.squeezeplayadmin',
	'defaultLevel' => 'WARN',
	'description'  => 'PLUGIN_SQUEEZEPLAYADMIN',
});
my $responses = {};
my $counter = 0;
my $servers = {};

sub getDisplayName {
	return 'PLUGIN_SQUEEZEPLAYADMIN';
}

sub initPlugin {
	my $class = shift;
	$class->SUPER::initPlugin(@_);
	$PLUGINVERSION = Slim::Utils::PluginManager->dataForPlugin($class)->{'version'};
	Slim::Control::Request::addDispatch(['squeezeplayadmin','register','_id','_model','_secret','_supportedCommands'],[0,1,0,\&registerCallback]);

	${Slim::Music::Info::suffixes}{'binfile'} = 'binfile';
	${Slim::Music::Info::types}{'binfile'} = 'application/octet-stream';
}

sub getFunctions {
	return {}
}

sub webPages {

	my %pages = (
		"plugins\/SqueezePlayAdminClient\/index\.(?:htm|xml).*"     => \&handleWebList,
		"plugins\/SqueezePlayAdminClient\/viewfile\..*"     => \&handleWebFile,
	);

	for my $page (keys %pages) {
		if(UNIVERSAL::can("Slim::Web::Pages","addPageFunction")) {
			Slim::Web::Pages->addPageFunction($page, $pages{$page});
		}else {
			Slim::Web::HTTP::addPageFunction($page, $pages{$page});
		}
		Slim::Web::HTTP::CSRF->protectURI($page);
	}
	Slim::Web::Pages->addPageLinks("plugins", { 'PLUGIN_SQUEEZEPLAYADMIN' => 'plugins/SqueezePlayAdminClient/index.html' });
}

sub getNewHandle {
	my $handle = $counter++;
	if($counter>1000) {
		$counter = 0;
	}
	return $handle;
}

sub handleWebList {
	my ($client, $params, $callback, $httpClient, $response) = @_;

	if (!$serverPrefs->get('csrfProtectionLevel') && !$serverPrefs->get('authorize')) {
		$params->{'pluginSqueezePlayAdminWarning'} = $client->string("PLUGIN_SQUEEZEPLAYADMIN_SECURITY_WARNING");
	}

	my $handle = getNewHandle();
	
	my $dir = "/";
	if(defined($params->{'dir'}) && $params->{'dir'} ne "") {
		$dir = $params->{'dir'};
	}

	my $server = $params->{'server'};
	my @serverList = ();
	for my $serverId (keys %$servers) {
		my $entry = {
			'id' => $serverId,
			'name' => $servers->{$serverId}->{'name'}." (".$servers->{$serverId}->{'model'}.")",
		};
		push @serverList,$entry;
	}

	if((!defined($server) || $server eq "") && scalar(@serverList)>0) {
		if(!defined($params->{'pluginSqueezePlayAdminWarning'})) {
			# Not working on LMS 8.2  : "Can't use an array as a reference"
			# so quick and dirty comment
			#$server = $serverList->[0]->{'id'}
		}
	}
	$params->{'pluginSqueezePlayAdminServers'} = \@serverList;
	$params->{'pluginSqueezePlayAdminVersion'} = $PLUGINVERSION;

	if(defined($server) && $server ne "") {
		my $secret = $servers->{$server}->{'secret'};
		my $requestParams = {
			'dir' => $dir,
		};
		$params->{'pluginSqueezePlayAdminCurrentServer'} = $server;
		$params->{'pluginSqueezePlayAdminCurrentDirectory'} = $dir;
		$responses->{$handle} = {
			'params' => $params,
			'webCallback' => $callback,
			'callback' => \&getDirResponse,
			'httpClient' => $httpClient,
			'response' => $response,
			'timeout' => 30
		};
		Slim::Control::Request::notifyFromArray(undef,["squeezeplayadmin.dir",$server,$secret,$handle,$requestParams]);
		return undef;
	}else {
		return Slim::Web::HTTP::filltemplatefile('plugins/SqueezePlayAdminClient/index.html', $params);
	}
}

sub handleWebFile {
	my ($client, $params, $callback, $httpClient, $response) = @_;

	my $handle = getNewHandle();
	my $file = $params->{'file'};

	my $server = $params->{'server'};
	my $secret = $servers->{$server}->{'secret'};
	$params->{'pluginSqueezePlayAdminClientVersion'} = $PLUGINVERSION;
	$responses->{$handle} = {
		'params' => $params,
		'webCallback' => $callback,
		'callback' => \&getFileResponse,
		'httpClient' => $httpClient,
		'response' => $response,
		'timeout' => 30
	};
	my $requestParams = {
		file => $file,
	};
	Slim::Control::Request::notifyFromArray(undef,["squeezeplayadmin.get",$server,$secret,$handle,$requestParams]);

	return undef;
}

sub registerCallback {
	my $request = shift;

	my $id = $request->getParam("_id");
	my $model = $request->getParam("_model");
	if($model eq 'jive') {
		$model = "Controller";
	}elsif($model eq 'fab4') {
		$model = "Touch";
	}elsif($model eq 'baby') {
		$model = "Radio";
	}elsif($model eq 'squeezeplay') {
		$model = "SqueezePlay";
	}
	
	my $supportedCommands = $request->getParam("_supportedCommands");
	my $client = Slim::Player::Client::getClient($id);
	if($client) {
		$servers->{$id} = {
			id => $id,
			name => $client->name,
			model => $model,
			secret => $request->getParam("_secret"),
			supportedCommands => $supportedCommands,
		};
	}else {
		$servers->{$id} = {
			id => $id,
			name => $id,
			model => $model,
			secret => $request->getParam("_secret"),
			supportedCommands => $supportedCommands,
		};
	}
	for my $key (keys %$supportedCommands) {
		Slim::Control::Request::addDispatch(['squeezeplayadmin.'.$key],[0,1,0,undef]);
		Slim::Control::Request::addDispatch(['squeezeplayadmin',$supportedCommands->{$key},'_handle','_data'],[0,1,0,sub { handleResponse($key,@_); }]);
		Slim::Control::Request::addDispatch(['squeezeplayadmin',$key,'_device'],[0,1,1,sub { handleCommand($key,@_); }]);
	}

	$log->info("Registering: ".Dumper($servers->{$id}));
	$request->setStatusDone();
}

sub handleCommand {
	my $cmd = shift;
	my $request = shift;
	my $client = $request->client();
	my $params = $request->getParamsCopy();

	my $handle = getNewHandle();
	my $server = $request->getParam('_device');
	if(defined($server) && defined($servers->{$server})) {
		if(defined($cmd) && defined($servers->{$server}->{'supportedCommands'}->{$cmd})) {
			my $secret = $servers->{$server}->{'secret'};
			$responses->{$handle} = {
				'request' => $request,
			};
			Slim::Control::Request::notifyFromArray(undef,["squeezeplayadmin.".$cmd,$server,$secret,$handle,$params]);
			$request->setStatusProcessing();
		}else {
			$log->warn("$cmd is not a supported command");
			$request->setStatusBadDispatch();
		}
	}else {
		$log->warn("$server is not available");
		$request->setStatusBadParams();
	}
}

sub handleResponse {
	my $cmd = shift;
	my $request = shift;
	my $client = $request->client();

	my $handle = $request->getParam("_handle");
	return unless exists $responses->{$handle};

	my $data = $request->getParam("_data");

	if(defined($responses->{$handle}->{'request'})) {
		for my $key (keys %$data) {
			if(ref($data->{$key}) eq 'ARRAY') {
				my $cnt = 0;
				my $array = $data->{$key};
				for my $entry (@$array) {
					if(ref($entry) eq 'HASH') {
						for my $entryKey (keys %$entry) {
							$responses->{$handle}->{'request'}->addResultLoop($key,$cnt,$entryKey,$entry->{$entryKey})
						}
					}else {
						$responses->{$handle}->{'request'}->addResultLoop($key,$cnt,"data",$entry)
					}
					$cnt++;
				}
				if(!defined($data->{'count'})) {
					$responses->{$handle}->{'request'}->addResult('count',$cnt);
				}
			}else {
				$responses->{$handle}->{'request'}->addResult($key,$data->{$key});
			}
		}
		$responses->{$handle}->{'request'}->setStatusDone();
	}
	$request->setStatusDone();
	if($responses->{$handle}->{'callback'}) {
		$responses->{$handle}->{'callback'}->($client,$responses->{$handle},$data);
	}
	delete $responses->{$handle};
}

sub getFileResponse {
	my $client = shift;
	my $response = shift;
	my $data = shift;

	my $file = $data->{'filename'};
	my $basefile;
	if($file =~ /^.*\/([^\/]+)$/) {
		$basefile = $1;
	}
	my $content = $data->{'content'};
	if(defined($content)) {
		$content = MIME::Base64::Perl::decode_base64($content);
	}

	my $params = $response->{'params'};
	$response->{'response'}->header("Content-Disposition","attachment; filename=".$basefile);
	$response->{'webCallback'}->($client,$params,\$content, $response->{'httpClient'},$response->{'response'});
}

sub getDirResponse {
	my $client = shift;
	my $response = shift;
	my $data = shift;

	my $files = $data->{'files'}; 
	@$files = sort {$a->{'name'} cmp $b->{'name'}} @$files;
	for my $file (@$files) {
		if($file->{'type'} eq 'file' && ($file->{'fullpath'} =~ /\/var\/log\/[^\.]+$/ || $file->{'fullpath'} =~ /\/var\/log\/.+\.[0-9]+$/ || $file->{'fullpath'} =~ /\/var\/log\/.+\.log$/)) {
			$file->{'extension'} = 'log';
		}else {
			$file->{'extension'} = 'binfile';
		}
		if(defined $file->{'size'}) {
			if($file->{'type'} eq 'file') {
				if($file->{'size'}>1024*1024*1024) {
					$file->{'size'} = sprintf("%.2f GB",($file->{'size'}/1024/1024/1024));
				}elsif($file->{'size'}>1024*1024) {
					$file->{'size'} = sprintf("%.2f MB",($file->{'size'}/1024/1024));
				}elsif($file->{'size'}>1024) {
					$file->{'size'} = sprintf("%.2f KB",($file->{'size'}/1024));
				}else {
					$file->{'size'} = $file->{'size'}." B"
				}
			}else {
				$file->{'size'} = '';
			}
		}
	}	

	my $params = $response->{'params'};
	$params->{'pluginSqueezePlayAdminItems'} = $files;
	my $content = Slim::Web::HTTP::filltemplatefile('plugins/SqueezePlayAdminClient/index.html', $params);
	$response->{'webCallback'}->($client,$params,$content, $response->{'httpClient'},$response->{'response'});
}

1;

__END__
