# NOTE -- This file is generated by running make-js-interfaces.pl
package ie;

use strict;
use vars qw/@ISA $standardheader/;
$standardheader = <<EOF;
<!-- This is part of CGI:IRC 0.5
  == http://cgiirc.sourceforge.net/
  == Copyright (C) 2000-2002 David Leadbeater <cgiirc\@dgl.cx>
  == Released under the GNU GPL
  -->
EOF

use default;
@ISA = qw/default/;
my %colours = (
	  '00' => '#FFFFFF', '01' => '#000000', '02' => '#0000FF', 
	  '03' => '#008000', '04' => '#FF0000', '05' => '#800000', 
	  '06' => '#800080', '07' => '#FF6600', '08' => '#FFFF00', 
	  '09' => '#00FF00', '10' => '#008080', '11' => '#00FFFF', 
	  '12' => '#0000FF', '13' => '#FF00FF', '14' => '#808080', 
	  '15' => '#C0C0C0');

my %options = (
   timestamp => {
      type => 'toggle',
      info => 'Display a timestamp next to each message', 
      img => 'time.gif'
   },
   font => { 
      type => 'select',
      options => [qw/serif sans-serif fantasy cursive monospace/,
                 'Arial Black', 'Comic Sans MS', 'Fixedsys',
                 'Tahoma', 'Verdana'],
      info => 'The font that messages are displayed in',
      img => 'font.gif'
   },
   shownick => {
      type => 'toggle',
      info => 'Show your nickname next to the text entry box',
      img => 'entry.gif'
   },
   smilies => {
      type => 'toggle',
      info => 'Convert smilies into pictures',
      img => 'smile.gif'
   },
   scrollback => {
      type => 'toggle',
      info => 'Store all scrollback data (uses more memory)'
   },
);

sub new {
   my($class,$event, $timer, $config, $icookies) = @_;
   my $self = bless {}, $class;
   tie %$self, 'IRC::UniqueHash';
   my $tmp='';
   for(keys %$icookies) {
      $tmp .= "$_: " . _escapejs($icookies->{$_}) . ', ';
   }
   $tmp =~ s/, $//;
   _out('parent.options = { ' . $tmp . '};');
   $event->add('user add', code => \&useradd);
   $event->add('user del', code => \&userdel);
   $event->add('user change nick', code => \&usernick);
   $event->add('user change', code => \&usermode);
   $event->add('user self', code => \&mynick);
   $event->add('user 005', code => sub { _func_out('prefix',$_[1])});
   _out('parent.connected = 1;');
   $self->add('Status', 0);
   _func_out('witemnospeak', 'Status');
   _func_out('fontset', $icookies->{font}) if exists $icookies->{font};
   return $self;
}

sub end {
   _out('parent.connected = 0;');
}

sub _out {
   print "<script>$_[0]</script>\r\n";
}

sub _func_out {
   my($func,@rest) = @_;
   @rest = map(ref $_ eq 'ARRAY' ? _outputarray($_) : _escapejs($_), @rest);
   if($func eq 'witemaddtext') {
      return 'parent.' . $func . '(' . _jsp(@rest) . ');';
   }
   _out('parent.' . $func . '(' . _jsp(@rest) . ');');
}

sub _escapejs {
   my $in = shift;
   return "''" unless defined $in;
   $in =~ s/\\/\\\\/g;
   $in =~ s/'/\\'/g;
   $in =~ s/<\/script/<\\\/\\script/g;
   if(defined $_[0]) {
      return "$_[0]$in$_[0]";
   }
   return '\'' . $in . '\'';
}

sub _escapehtml {
   my $in = shift;
   return "''" unless defined $in;
   $in =~ s/</&lt;/g;
   $in =~ s/>/&gt;/g;
   $in =~ s/"/&quot;/g;
   return $in;
}

sub _jsp {
   return join(', ', @_);
}

sub _outputarray {
   my $array = shift;
   return '[' . _jsp(map(_escapejs($_), @$array)) . ']';
}

sub useradd {
   my($event, $nicks, $channel) = @_;
   _func_out('channeladdusers', $channel, $nicks);
}

sub userdel {
   my($event, $nick, $channels) = @_;
   _func_out('channelsdeluser', $channels, $nick);
}

sub usernick {
   my($event,$old,$new,$channels) = @_;
   _func_out('channelsusernick', $old, $new);
}

sub usermode {
   my($event,$nick, $channel, $action, $type) = @_;
   _func_out('channelusermode', $channel, $nick, $action, $type);
}

sub mynick {
   my($event, $nick) = @_;
   _func_out('mynick', $nick);
}

sub exists {
   return 1 if defined &{__PACKAGE__ . '::' . $_[1]};
}

sub query {
   return 1;
}

sub style {
   my($self, $cgi, $config) = @_;
   my $style = $cgi->{style} || 'default';
   $cgi->{style} =~ s/[^a-z]//gi;
   open(STYLE, "<interfaces/style-$style.css") or die("Error opening stylesheet $style: $!");
   print <STYLE>;
   close(STYLE);
}

sub positionjs {
print <<EOF;
// position.js: make edge-positioning work on IE
// version 0.3, 18-Apr-2002; requires event.js
// written by Andrew Clover <and\@doxdesk.com>, use freely

var position_h= new Array();
var position_v= new Array();
var position_viewport;
var position_width= 0;
var position_height= 0;
var position_fontsize= 0;
var position_ARBITRARY= 200;

/* Binding. Called on each new element; if the it's <body>, initialise script.
   Check all new elements to see if they need our help, make lists of them */

function position_bind(el) {
  if (!position_viewport) {
    if (!document.body) return;
    // initialisation
    position_viewport= (document.compatMode=='CSS1Compat') ?
      document.documentElement : document.body;
    event_addListener(window, 'resize', position_delayout);
    var em= document.createElement('div');
    em.setAttribute('id', 'position_em');
    em.style.position= 'absolute'; em.style.visibility= 'hidden';
    em.style.fontSize= 'xx-large'; em.style.height= '10em';
    em.style.setExpression('width', 'position_checkFont()');
    document.body.appendChild(em);
  }

  // check for absolute edge-positioned elements (ignore ones from fixed.js!)
  var st= el.style; var cs= el.currentStyle;
  if (cs.position=='absolute' && !st.fixedPWidth) {
    if (cs.left!='auto' && cs.right!='auto') {
      position_h[position_h.length]= el;
      st.position_width= position_ARBITRARY;
      st.width= st.position_width+'px';
      position_delayout();
    }
    if (cs.top!='auto' && cs.bottom!='auto') {
      position_v[position_v.length]= el;
      st.position_height= position_ARBITRARY;
      st.height= st.position_height+'px';
      position_delayout();
  } }
}

function position_checkFont() { position_delayout(); return '1em'; }

/* Layout. For each edge-positioned axis, measure difference between min-edge
   and max-edge positioning, set size to the difference */

// Request re-layout at next available moment
var position_delaying= false;
function position_delayout() {
  if (position_delaying) return;
  position_delaying= true;
  window.setTimeout(position_layout, 0);
}

function position_layout() {
  position_delaying= false;
  var i, el, st, pos, tmp;
  var fs= document.all['position_em'].offsetWidth;
  var newfs= (position_fontsize!=fs && position_fontsize!=0);
  position_fontsize= fs;

  // horizontal axis
  if (position_viewport.clientWidth!=position_width || newfs) {
    position_width= position_viewport.clientWidth;
    for (i= position_h.length; i-->0;) {
      el= position_h[i]; st= el.style; cs= el.currentStyle;
      pos= el.offsetLeft; tmp= cs.left; st.left= 'auto';
      st.position_width+= el.offsetLeft-pos; st.left= tmp;
      if (st.position_width<1) st.position_width= 1;
      st.width= st.position_width+'px';
  } }
  // vertical axis
  if (position_viewport.clientHeight!=position_height || newfs) {
    position_height= position_viewport.clientHeight;
    for (i= position_v.length; i-->0;) {
      el= position_v[i]; st= el.style; cs= el.currentStyle;
      pos= el.offsetTop; tmp= cs.top; st.top= 'auto';
      st.position_height+= el.offsetTop-pos; st.top= tmp;
      if (st.position_height<1) st.position_height= 1;
      st.height= st.position_height+'px';
  } }
}

/* Start. If IE, get event to call us back on every new element */

if (window.clientInformation) {
  event_addBinding('*', position_bind);
}

EOF
}

sub eventjs {
print <<EOF;
// event.js: cross-browser Listener-style event handling
// version 0.8, 18-Apr-2001
// written by Andrew Clover <and\@doxdesk.com>, use freely

event_list= new Array();

event_level= 0;
if (document.implementation)
  if (document.implementation.hasFeature('Events', '2.0'))
    event_level= 2;

function event_addListener(esource, etype, elistener) {
  var i;
  var alreadyTriggering= false;
  for (i= 0; i<event_list.length; i++) {
    if (event_list[i][0]==esource && event_list[i][1]==etype) {
      if (event_list[i][2]==elistener) return;
      alreadyTriggering= true;
  } }
  event_list[event_list.length]= new Array(esource, etype, elistener);
  if (!alreadyTriggering) {
    if (event_level==2) {
      esource.addEventListener(etype, event_trigger_DOM2, true);
    } else {
      eval(event_trigger_DOM0(etype));
      esource['on'+etype]= event_trigger;
      if (esource.captureEvents)
        esource.captureEvents('Event.'+etype.toUpperCase());
  } }
}

function event_removeListener(esource, etype, elistener) {
  var i; var e;
  var j= 0;
  var removedListener= false;
  var keepTrigger= false;
  for (i= 0; i<event_list.length; i++) {
    if (event_list[i][0]==esource && event_list[i][1]==etype) {
      if (event_list[i][2]==elistener) {
        removedListener= true;
        continue;
      }
      else keepTrigger= true;
    }
    if (i!=j) event_list[j]= event_list[i];
    j++;
  }
  event_list.length= j;
  if (removedListener && !keepTrigger) {
    if (event_level==2)
      esource.removeEventListener(etype, elistener, true);
    else
      esource['on'+etype]= window.clientInformation ? null : window.undefined;
  }
}

function event_trigger_DOM2(e) {
  if (event_dispatch(this, e.type)==false)
    e.preventDefault();
}

function event_trigger_DOM0(t) {
  return 'function event_trigger() {return event_dispatch(this, \\''+t+'\\');}';
}

function event_dispatch(esource, etype) {
  var i; var r;
  var elisteners= new Array();
  var result= window.undefined;
  for (i= 0; i<event_list.length; i++)
    if (event_list[i][0]==esource && event_list[i][1]==etype)
      elisteners[elisteners.length]= event_list[i][2];
  for (i= 0; i<elisteners.length; i++) {
    r= elisteners[i](esource, etype);
    if (r+''!='undefined') result= r;
  }
  return result;
}

// convenience prevent-default-action listener
function event_prevent(esource, etype) { return false; }

// page finished loading detector for binding
var event_loaded= false;
function event_load(esource, etype) {
  event_loaded= true;
  event_removeListener(window, 'load', event_load);
}
event_addListener(window, 'load', event_load);

// binding helper
var event_BINDDELAY= 750;
var event_binds= new Array();

function event_addBinding(btag, blistener) {
  event_binds[event_binds.length]= new Array(btag, 0, blistener);
  if (event_intervalling)
    event_bind();
  else {
    event_intervalling= true;
    window.setTimeout(event_interval, 0);
  }
}

var event_intervalling= false;
function event_interval() {
  event_bind();
  if (!event_loaded)
    window.setTimeout(event_interval, event_BINDDELAY);
}

function event_bind() {
  var i, j, els, blistener;
  for (i= event_binds.length; i-->0;) {
    els= event_getElementsByTag(event_binds[i][0]);
    blistener= event_binds[i][2];
    for (j= event_binds[i][1]; j<els.length; j++)
      blistener(els[j]);
    event_binds[i][1]= event_getElementsByTag(event_binds[i][0]).length;
  }
}

// get elements by tag name with backup for pre-DOM browsers
var event_NIL= new Array();
function event_getElementsByTag(tag) {
  if (document.getElementsByTagName) {
    var arr= document.getElementsByTagName(tag);
    // IE5.0/Win doesn't support '*' for all tags
    if (tag!='*' || arr.length>0) return arr;
  }
  if (document.all) {
    if (tag=='*') return event_array(document.all);
    else return event_array(document.all.tags(tag));
  }
  tag= tag.toLowerCase();
  if (tag=='a') return event_array(document.links);
  if (tag=='img') return event_array(document.images);
  if (tag=='form') return event_array(document.forms);
  if (document.layers && tag=='div') return event_array(document.layers);
  return event_NIL;
}
function event_array(coll) {
  var arr= new Array(coll.length);
  for (var i= arr.length; i-->0;)
    arr[i]= coll[i];
  return arr;
}

EOF
}

sub makeline {
   my($self, $info, $html) = @_;
   my $target = defined $info->{target} ? $info->{target} : 'Status';

   if(ref $target eq 'ARRAY') {
     my %tmp = %$info;
     my $text = '';
	  for(@$target) {
	     $tmp{target} = $_;
        $text .= $self->makeline(\%tmp, $html) . "\r\n";
	  }
	  return $text;
   }

   if(not exists $self->{$target}) {
      if(defined $info && ref $info && exists $info->{create} && $info->{create}) {
	     $self->add($target, $info->{type} eq 'join' ? 1 : 0);
	  }elsif($target ne '-all') {
         $target = 'Status';
	  }
   }
   if($info->{style}) {
      $html = "<span class=\"main-$info->{style}\">$html</span>";
   }
   return _func_out('witemaddtext', $target, $html . '<br>', $info->{activity} || 0, 0);
}

sub lines {
   my($self, @lines) = @_;
   _out(join("\r\n", @lines)."\r\nparent.witemredraw();");
}

sub header {
   my($self, $cgi, $config, $fg, $bg) = @_;
   _func_out('maincolor', $fg, $bg);
}

sub error {
   my($self,$message) = @_;
   $self->lines($self->makeline({ target => 'Status'}, $message));
   _func_out('disconnected');
}

sub add {
   my($self,$add,$channel) = @_;
   return if not defined $add;
   $self->{$add}++;
   _func_out('witemadd', $add, $channel);
   _func_out('witemchg', $add) if $channel;
}

sub del {
   my($self, $del) = @_;
   return if not defined $del;
   _func_out('witemdel', $del);
   return if not exists $self->{$del};
   delete($self->{$del});
}

sub clear {
   my($self, $window) = @_;
   _func_out('witemclear', $window);
}

sub active {
   my($self, $window) = @_;
   _func_out('witemchg', $window);
}

sub smilie { # js runs in fmain.
   shift; # object
   my $x = "sm" . int(rand(200000));
   return '<img name="'.$x.'" alt=""><script>parent.fwindowlist.smilie(' . _jsp(map(_escapejs($_,'"'), $_[0], $x, $_[2])) . ');</script>';
}

sub link {
   shift; # object
   return "<a href=\"$_[0]\" target=\"cgiirc@{[int(rand(200000))]}\" class=\"main-link\">$_[1]</a>";
}

sub frameset {
   my($self, $scriptname, $config, $random, $out, $interface, $style) = @_;
print <<EOF;
$standardheader
<html>
<head>
<script src="$scriptname?item=eventjs&interface=$interface"></script>
<script src="$scriptname?item=positionjs&interface=$interface"></script>
<title>CGI:IRC - Loading</title>
<link rel="stylesheet" href="$config->{script_login}?interface=ie&item=style&style=$style" />
<link rel="SHORTCUT ICON" href="$config->{image_path}/favicon.ico">
<script language="JavaScript"><!--
function form_focus() {
   if(document.frames && document.frames.fform)
	  document.frames.fform.fns();
}
//-->
</script>
</head>
<body onload="form_focus()" onfocus="form_focus()" class="frame-body">
<iframe name="fwindowlist" src="$scriptname?$out&item=fwindowlist&style=$style" scrolling="no" class="frame-windowlist"></iframe>
<iframe name="fmain" src="$scriptname?item=fmain&interface=$interface&style=$style" scrolling="yes" class="frame-main"></iframe>
<iframe name="fuserlist" src="$scriptname?item=fuserlist&interface=$interface&style=$style" scrolling="yes" class="frame-userlist"></iframe>
<iframe name="fform" src="$scriptname?item=fform&interface=$interface&style=$style" scrolling="no" framespacing="0" border="0" frameborder="0" resize="no" class="frame-form"></iframe>
</body>
</html>
EOF
}

sub blank {
   return '';
}

sub ctcpping {
   my($self, $nick, $params) = @_;
   _func_out('sendcmd',"/ctcpreply $nick PING $params");
   1;
}

sub ping {
   1;
}

sub sendping {
   _func_out('sendcmd',"/noop");
}

sub help {
   my($self,$config) = @_;
   my $help = <<EOF;
<!-- this is included in ie.pm and mozilla.pm by make-js-interfaces.pl -->
<h1>CGI:IRC Help</h1>

<h3>Interface</h3>

The interface of CGI:IRC is very similar to a standard graphical IRC client, it
 should be easy to use if you are familiar with IRC clients. Along the top is a
 list of tabs, there will be a tab here for each channel you are in and each
 query (private message) you have open. To close a window click the X button on
 the far right of the tab list.<br />
The userlist is on the right, when in a channel tab it will show a list of all
 the people in that channel. Double clicking a nickname will open a query with
 that user or perform whichever other action you select in the select box at the
 bottom.<br />
The text entry box should be simple, the little arrow to the right of the text
 entry area shows a toolbar that allows easy typing of colour, bold and underline. It is also where you enter all the commands.

<h3>Commands</h3>
Commands begin with / and should be familiar to anyone who has used IRC before
- here is a quick summary of the most useful commands.
<table>
<tr><td>/me</td><td>This turns the text after /me into an action, eg: /me looks
around.</td></tr>
<tr><td>/join</td><td>Joins the specified channel. eg: /join #cgiirc</td></tr>
<tr><td>/list</td><td>Lists all the channels on the network (this outputs a lot
of information).</td></tr>
<tr><td>/part</td><td>Leaves the current channel (same as clicking the X while
in the channel).</td></tr>
<tr><td>/quit</td><td>Quits IRC totally (same as clicking X in Status window).</td></tr>
<tr><td>/msg</td><td>Sends a private message to a user. eg: /msg someone Hi</td></tr>
<tr><td>/whois</td><td>Gives some information about a user.</td></tr>
</table>

<h3>Options</h3>
The options window lets you change some settings in CGI:IRC. Hopefully it
 should be fairly self explanatory, change a setting and it should take effect
 immediately.

<h3>Keyboard shortcuts</h3>
There are several shortcuts to help make using CGI:IRC nicer, tab completion
 which will complete a nickname or channel when you press tab, alt+number will
 go to that number window if you number the windows from the left (Status = 1
 and so on).

<h3>About CGI:IRC</h3>
CGI:IRC is written in Perl by David Leadbeater with help from lots of people. See the <a
 href="http://cgiirc.sourceforge.net/" target="cgiirc-web">website</a> for more information.
EOF
   $help =~ s/[\n\r]/ /g;
   _func_out('doinfowin', '-Help', $help);
}

sub setoption {
   my($self, $name, $value) = @_;
   _func_out('setoption', $name, $value);
   $self->options({}, {}, $main::config)
}

sub options {
   my($self, $cgi, $irc, $config) = @_;
   $config = $irc unless ref $config;
   my $ioptions = $main::ioptions;

   my $out = "<html><head><title>CGI:IRC Options</title></head><body class=\"options-body\"><h1 class=\"options-title\">Options</h1>These options affect the appearence of CGI:IRC, they will stay between sessions provided cookies are turned on.<form><table border=0 class=\"options-table\"> ";

   for my $option(keys %options) {
      my $o = $options{$option};
      my $value = defined $ioptions->{$option} ? $ioptions->{$option} : '';
      
      $out .= "<tr><td>" . (exists $o->{img} ? "<label for=\"$option\"><img src=\"$config->{image_path}/$o->{img}\"> " : '') . "<b>$option</b>" . (exists $o->{info} ? " ($o->{info})" : '') . "</td><td>";
      if($o->{type} eq 'toggle') {
         $out .= "<input class=\"options-checkbox\" type=\"checkbox\" name=\"$option\" value=\"1\"" . 
            ($value? ' checked=1' : '')."\" onclick=\"parent.fwindowlist.send_option(this.name, this.checked == true ? this.value : 0);return true;\">";
      }elsif($o->{type} eq 'select') {
         $out .= "<select name\"$option\" onchange=\"parent.fwindowlist.send_option('$option', this.options[this.selectedIndex].value);return true\" class=\"options-select\">";
         for(@{$o->{options}}) {
            $out .= "<option class=\"options-option\" name=\"$option\" value=\"$_\"".($_ eq $value ? ' selected=1' : '') . ">$_</option>";
         }
         $out .= "</select>";
      }else{
         $out .= "<input class=\"options-input\" type=\"text\" name=\"$option\" value=\""._escapehtml($value)."\" onChange=\"parent.fwindowlist.send_option(this.name, this.value);return true;\">";
      }
      $out .= "</label></td></tr>";
   }
   
$out .= "
</table></form><span onclick=\"parent.fwindowlist.witemdel('-Options')\" class=\"options-close\">close</span></body></html>
";
   $out =~ s/\n//g;
   _func_out('doinfowin', '-Options', $out);
}

sub say {
   my($self) = @_;
   return 'ok';
}

sub fwindowlist {
   my($self, $cgi, $config) = @_;
   my $string;
   for(keys %$cgi) {
      next if $_ eq 'item';
	  $string .= main::cgi_encode($_) . '=' . main::cgi_encode($cgi->{$_}).'&';
   }
   $string =~ s/\&$//;
print $standardheader;
print q~
<html>
<head>
<script language="JavaScript">
<!--
// This javascript code is released under the same terms as CGI:IRC itself
// http://cgiirc.sourceforge.net/
// Copyright (C) 2000-2002 David Leadbeater <cgiirc\@dgl.cx>

//               none      joins    talk       directed talk
var activity = ['#000000','#000099','#990000', '#009999'];

var Witems = {};
var options = {};
var currentwindow = '';
var lastwindow = '';
var connected = 0;
var mynickname = '';
var prefixchars = '@%+ ';

document.onselectstart = function() { return false; }
document.onmouseup = function() {
   if(event.button != 2) return true;
   event.returnVal = false;
   return false;
}
document.oncontextmenu = function() {
   return false;
}
document.onhelp = function() {
   sendcmd('/help');
   return false;
}

function witemadd(name, channel) {
   if(Witems[name] || findwin(name)) return;
   name = name.replace(/\"/g, '&quot;');
   Witems[ name ] = { activity: 0, text: new Array, channel: channel, speak: 1,  info: 0 };
   if(channel) {
      Witems[name].users = {};
	  Witems[name].topic = '';
   }
   if(!currentwindow) currentwindow = name;
   wlistredraw();
}

function witemnospeak(name) {
   if(!Witems[name] && !(name = findwin(name))) return;
   Witems[name].speak = 0;
}

function witeminfo(name) {
   if(!Witems[name] && !(name = findwin(name))) return;
   Witems[name].info = 1;
}

function witemdel(name) {
   if(!Witems[name] && !(name = findwin(name))) return;
   if(name == 'Status') return;
   delete Witems[name];
   if(currentwindow == name) witemchg(lastwindow ? lastwindow : 'Status');
}

function witemclear(name) {
   if(!Witems[name] && !(name = findwin(name))) return;
   Witems[name].text.length = 0;
   witemredraw();
}


function channeladdusers(channel, users) {
   for(var i = 0;i < users.length;i++) {
      channeladduser(channel, users[i]);
   }
   userlist();
}

function channeladduser(channel, user) {
   var o = user.substr(0,1);
   if(prefixchars.lastIndexOf(o) != -1)
      user = user.substr(1);

   if(!Witems[channel] && !(channel = findwin(channel))) return;

   Witems[channel].users[user] = { };

   if(o == '@') Witems[channel].users[user].op = 1;
   else if(o == '%') Witems[channel].users[user].halfop = 1;
   else if(o == '+') Witems[channel].users[user].voice = 1;
   else if(prefixchars.lastIndexOf(o) != -1)
      Witems[channel].users[user].other = o;
}

function channelsdeluser(channels, user) {
   if(channels == '-all-') {
      for(var i in Witems) {
         if(!Witems[i].channel) continue;
         if(!Witems[i].users[user]) continue;
         channeldeluser(i, user);
      }
      return;
   }
   for(var i = 0;i < channels.length; i++) {
      channeldeluser(channels[i], user);
   }
   userlist();
}

function channeldeluser(channel, user) {
   if(!Witems[channel] && !(channel = findwin(channel))) return;
   delete Witems[channel].users[user];
   userlist();
}

function channelsusernick(olduser, newuser) {
   for(var channel in Witems) {
      if(!Witems[channel].channel) continue;
      for(var nick in Witems[channel].users) {
	      if(nick == olduser) {
            Witems[channel].users[newuser] = Witems[channel].users[olduser];
            delete Witems[channel].users[olduser];
		   }
	   }
   }
   userlist();
}

function channelusermode(channel, user, action, type) {
   if(!Witems[channel] && !(channel = findwin(channel))) return;
   if(!Witems[channel].users[user]) return;

   if(action == '+') {
      Witems[channel].users[user][type] = 1;
   }else{
      delete(Witems[channel].users[user][type]);
   }
   userlist();
}

function channellist(channel) {
   if(!Witems[channel] && !(channel = findwin(channel))) return;
   var users = new Array();

   for (var i in Witems[channel].users) {
      var user = Witems[channel].users[i];
      if(user.other) i = user.other + i;
     else if(user.op == 1) i = '@' + i
	  else if(user.halfop == 1) i = '%' + i;
	  else if(user.voice == 1) i = '+' + i;
     else   i = ' ' + i;

      users[users.length] = i;
   }

   users = users.sort(usersort);
   return users;
}

function usersort(user1,user2) {
   var m1 = user1.substr(0,1);
   var m2 = user2.substr(0,1);

   if(m1 == m2) {
      if(user1.toUpperCase() < user2.toUpperCase()) return -1;
	  if(user2.toUpperCase() < user1.toUpperCase()) return 1;
	  return 0; // shouldn't happen :-)
   }else if(m1 == '@') {
      return -1;
   }else if(m2 == '@') {
      return 1;
   }else if(m1 == '%') {
      return -1;
   }else if(m2 == '%') {
      return 1;
   }else if(m1 == '+') {
      return -1;
   }else if(m2 == '+') {
      return 1;
   }else{
      if(user1.toUpperCase() < user2.toUpperCase()) return -1;
	  if(user2.toUpperCase() < user1.toUpperCase()) return 1;
	  return 0;
   }
}

function witemchg(name) {
   if(!Witems[name] && !(name = findwin(name))) name = 'Status';
   if(Witems[name].activity > 0) Witems[name].activity = 0;
   lastwindow = (Witems[currentwindow] ? currentwindow : 'Status');
   currentwindow = name;
   wlistredraw();
   witemredraw();
   formfocus();
   userlist();
   retitle();
}

function retitle() {
   parent.document.title = 'CGI:IRC - ' + (Witems[currentwindow].info ? currentwindow.substr(1) : currentwindow) + (Witems[currentwindow].channel == 1 ? ' [' + countit(Witems[currentwindow].users) + '] ' : '');
}

function setoption(option, value) {
   options[option] = value;
   if(option == 'shownick' && value == 1) {
      mynick(mynickname);
   }else if(option == 'shownick') {
      if(parent.fform && parent.fform.nickchange) parent.fform.nickchange('');
   }else if(option == 'font') {
      fontset(value);
   }
}

function mynick(mynick) {
   mynickname = mynick;
   if(options.shownick != 1) return;
   if(parent.fform && parent.fform.nickchange) parent.fform.nickchange(mynick);
}

function maincolor(bg, fg) {
   var maindoc = parent.fmain.document;
   if(!maindoc) return;
   maindoc.bgColor = bg;
   maindoc.fgColor = fg;
}

function prefix(chars) {
   prefixchars = chars;
}

function witemchgnum(num) {
   var count = 1;
   for(var name in Witems) {
      if(count++ == num) return name;
   }
   return false;
}

function countit(obj) {
   var i = 0;
   for(var foo in obj) i++;
   return i;
}

function witemaddtext(name, text, activity, redraw) {
   if(name == '-all') {
      for(var window in Witems) {
        if(Witems[window].info) continue;
	     witemaddtext(window, text, activity, redraw);
	  }
      return;
   }
   if(!Witems[name] && !(name = findwin(name))) {
      if(!Witems["Status"]) return;
	  name = "Status";
   }
   
   if(options["timestamp"] == 1 && !Witems[name].info) {
      var D = new Date();
      text = '[' + (D.getHours() < 10 ? '0' + D.getHours() : D.getHours()) + ':' + (D.getMinutes() < 10 ? '0' + D.getMinutes() : D.getMinutes()) + '] ' + text;
   }
  
   if(options["scrollback"] == 0)
      Witems[name].text = Witems[name].text.slice(Witems[name].text.length - 200);
   Witems[name].text[Witems[name].text.length] = text;
   if(currentwindow != name && activity > Witems[name].activity)
       witemact(name, activity);
   if(redraw != 0 && currentwindow == name) witemredraw();
}

function witemact(name, activity) {
   if(!Witems[name] && !(name = findwin(name))) return;
   Witems[name].activity = activity;
   wlistredraw();
}

function witemredraw() {
   if(!parent.fmain.document) {
      setTimeout("witemredraw()", 1000);
	  return;
   }
   if(!currentwindow) currentwindow = 'Status';
   parent.fmain.document.getElementById('text').innerHTML = Witems[currentwindow].text.join('');
   if(Witems[currentwindow].info == 1) return;
   var count = 0;
   var doc = parent.fmain.document.body;
   while(doc.scrollTop < doc.scrollHeight && count < 20) {
      doc.scrollTop = doc.scrollHeight;
      count++;
   }
}

function wlistredraw() {
   var output='';
   for (var i in Witems) {
      output += '<span class="' + (i == currentwindow ? 'wlist-active' : 'wlist-chooser') + '" style="color: ' + activity[Witems[i].activity] + ';" onclick="witemchg(\'' + (i == currentwindow ? escapejs(lastwindow) : escapejs(i)) + '\')" onmouseover="this.className = \'wlist-mouseover\'" onmouseout="this.className = \'' + (i == currentwindow ? 'wlist-active' : 'wlist-chooser') + '\'">' + escapehtml(Witems[i].info ? i.substr(1) : i) + '</span>\r\n';
   }
   document.getElementById('windowlist').innerHTML = output;
}

function findwin(name) {
   var wname = new String(name);
   wname = wname.replace(/\"/g, '&quot;');
   for (var i in Witems) {
      if (i.toUpperCase() == wname.toUpperCase())
	     return i;
   }
   return false;
}

function escapejs(string) {
   out = string.replace(/\\\\/g,'\\\\\\\\').replace(/\\'/g, '\\\\\\'').replace(/\"/g, '&quot;');
   return out;
}

function escapehtml(string) {
   var out = string;
   out = out.replace(/</g, '&lt;');
   out = out.replace(/>/g, '&gt;');
   out = out.replace(/\"/g, '&quot;');
   return out;
}

function reconnect() {
	  do_quit();
     Witems = { };
     document.getElementById('iframe').src = document.getElementById('iframe').src + '&xx=yy';
}

function sendcmd(cmd) {
   if(cmd.substr(0, 10) == '/reconnect') {
      reconnect();
      return;
   }

   if(!connected && cmd.substr(0,5) != '/quit') {
	  alert('Not connected to IRC!');
	  return;
   }
   if(Witems[currentwindow] && !Witems[currentwindow].speak && cmd.substr(0,1) != '/') return;
   sendcmd_real('say', cmd, currentwindow);
}

function sendcmd_userlist(action, user) {
   if(!Witems[currentwindow].channel) return;
   if(!connected) {
      alert('Not connected to IRC!');
      return;
   }
   sendcmd_real('say', '/' + action + ' ' + user, currentwindow);
}

function sendcmd_real(type, say, target) {
   document.hsubmit.item.value = 'say';
   document.hsubmit.cmd.value = type;
   document.hsubmit.say.value = say;
   document.hsubmit.target.value = target;
   document.hsubmit.submit();
}

function senditem(item) {
   document.hsubmit.item.value = item;
   document.hsubmit.cmd.value = '';
   document.hsubmit.say.value = '';
   document.hsubmit.target.value = '';
   document.hsubmit.submit();
}

function send_option(name, value) {
   document.hsubmit.item.value = '';
   document.hsubmit.cmd.value = 'options';
   document.hsubmit.say.value = '';
   document.hsubmit.target.value = '';
   document.hsubmit.name.value = name;
   document.hsubmit.value.value = value;
   document.hsubmit.submit();
   document.hsubmit.name.value = '';
   document.hsubmit.value.value = '';
}

function userlist() {
   if(!parent.fuserlist.userlist) {
      setTimeout(1000, "userlist()");
      return;
   }
   if(Witems[currentwindow] && Witems[currentwindow].channel == 1) {
      userlistupdate(channellist(currentwindow));
   }else{
      userlistupdate([' No channel']);
   }
   retitle();
}

function userlistupdate(list) {
   if(!parent.fuserlist.userlist) return;
   parent.fuserlist.userlist(list);
}

function formfocus() {
   if(parent.fform.location) parent.fform.fns();
}

function disconnected() {
   if(connected == 1) {
	  connected = 0;
	  do_quit();
	  witemaddtext('-all', '<b>Disconnected</b>', 1, 1);
   }
}

function doinfowin(name, text) {
   witemadd(name, 0);
   witemnospeak(name);
   witeminfo(name);
   witemclear(name);
   witemaddtext(name, text, 0, 1);
   witemchg(name);
}

function fontset(font) {
   if(parent.fmain.document.getElementById('text')) {
      parent.fmain.document.getElementById('text').style.fontFamily = font;
   }
}

var smilies = { };
function smilie(path, name, text) {
   alert(path);
   if(!smilies[path]) {
      smilies[path] = new Image();
      smilies[path].src = path;
   }
   parent.fmain.document.write('<img name="' + name + '">');
   parent.fmain.document.images[name].src = smilies[path].src;
   parent.fmain.document.images[name].alt = text;
}

~;
# ' (fix syntax hilight)
print <<EOF;
imghelpdn = new Image();
imghelpdn.src = "$config->{image_path}/helpdn.gif";
imghelpup = new Image();
imghelpup.src = "$config->{image_path}/helpup.gif";

imgoptionsdn = new Image();
imgoptionsdn.src = "$config->{image_path}/optionsdn.gif";
imgoptionsup = new Image();
imgoptionsup.src = "$config->{image_path}/optionsup.gif";

imgclosedn = new Image();
imgclosedn.src = "$config->{image_path}/closedn.gif";
imgcloseup = new Image();
imgcloseup.src = "$config->{image_path}/closeup.gif";

function do_quit() {
   var i = new Image();
   i.src = "$config->{script_form}?R=$cgi->{R}&cmd=quit";
}

// -->
</script>
<link rel="stylesheet" href="$config->{script_login}?interface=ie&item=style&style=$cgi->{style}" />
</head>
<body onload="wlistredraw()" onkeydown="formfocus()" onbeforeunload="do_quit()" onunload="do_quit()" class="wlist-body">
<noscript>Scripting is required for this interface</noscript>
<table class="wlist-table">
<tr><td width="1">
<iframe src="$config->{script_nph}?$string" id="iframe" width="1" height="1" style="display:none;" onreadystatechange="if(this.readyState=='complete')disconnected()"></iframe>

<iframe src="$config->{script_login}?item=blank&style=$style" id="iframe" width="1" height="1" style="display:none;" onreadystatechange="if(this.readyState=='complete')disconnected()" name="hiddenframe"></iframe>
document.onselectstart = function() { return false; }
// -->
</script>
<link rel="stylesheet" href="$config->{script_login}?interface=ie&item=style&style=$cgi->{style}" />
</head>

<body class="userlist-body">

<div class="userlist-div" id="usertable">

<table class="userlist-table">
<tr><td class="userlist-status"></td>
<td class="userlist-item">No channel</td></tr>
</table>

</div>

<form name="mform" onsubmit="return fsubmit(this)" class="userlist-form">
<input type="hidden" name="user">
<select name="action" class="userlist-select">
<option value="query">Query</option>
<option value="whois">Whois</option>
<option value="kick">Kick</option>
</select>
<input type="submit" class="userlist-btn" value="&gt;&gt;">
</form>

</body>
</html>
EOF
}
sub fform {
   my($self, $cgi, $config) = @_;
print <<EOF;
$standardheader
<html>
<head>
<html><head>
<script language="JavaScript"><!--
var shistory = [ ];
var hispos;
var tabtmp = [ ];
var tabpos;
var tablen;
var tabinc;

function fns(){
   if(!document.myform.say) return;
   document.myform.say.focus();
}

function t(item,text) {
   if(item.style.display == 'none') {
      item.style.display = 'inline';
	  text.value = '>>';
	  document.myform.say.style.width='40%'
   }else{
      item.style.display = 'none';
	  text.value = '<<';
	  document.myform.say.style.width='90%'
   }
   fns();
}

function load() {
   fns();
   document.getElementById('extra').style.display = 'none';
   document.onkeydown = enter_key_trap;
}

function append(a) {
   document.myform["say"].value += a;
   fns();
}

function cmd() {
   if(document.myform["say"].value.length < 1) return false;
   hisadd();
   tabpos = 0;
   tabtmp = [];
   parent.fwindowlist.sendcmd(document.myform["say"].value);
   document.myform["say"].value = ''
   return false;
}

function nickchange(nick) {
   if(document.getElementById('nickname'))
      document.getElementById('nickname').innerHTML = nick;
}

function hisadd() {
   shistory[shistory.length] = document.myform["say"].value;
   hispos = shistory.length;
}

function hisdo() {
   if(shistory[hispos]) {
      document.myform["say"].value = shistory[hispos];
   }else{
      document.myform["say"].value = '';
   }
}

function enter_key_trap(e) {
   if(e == null) {
      return keypress(event.srcElement, event.keyCode, event);
   }else{
      // mozilla dodginess
      return keypress(e.target, e.keyCode == 0 ? e.which : e.keyCode, e);
   }
}

function keypress(srcEl, keyCode, event) {
   if (srcEl.tagName != 'INPUT' || srcEl.name.toLowerCase() != 'say')
       return true;

   if(keyCode == 66 && event.ctrlKey) {
	   append('\%B');
   }else if(keyCode == 67 && event.ctrlKey) {
       append('\%C');
   }else if(keyCode == 9) { // TAB
       var tabIndex = srcEl.value.lastIndexOf(' ');
	   var tabStr = srcEl.value.substr(tabIndex+1 || tabIndex).toLowerCase();

       if(tabpos == tabIndex && !tabStr && tabtmp.length) {
	      if(tabinc >= tabtmp.length) tabinc = 0;
	      for(var i = (tabinc > 0 ? tabinc : 0); i < tabtmp.length;i++) {
			 srcEl.value = srcEl.value.substr(0, tabIndex - tablen) + 
			       tabtmp[i] + (tabIndex == tablen ? ': ' : ' ');
			 tabpos = (tabIndex == -1 ? 0 : tabIndex) + tabtmp[i].length - tablen + (tabIndex == tablen ? 1 : 0);
			 tablen = tabtmp[i].length + (tabIndex == tablen ? 1 : 0);
			 tabinc++;
			 break;
		  }
	   }else{
	      tabtmp = [];
	      var list = parent.fwindowlist.channellist(parent.fwindowlist.currentwindow);
		  for(var i = 0;i < list.length; i++) {
		     var item = list[i].replace(/^[+%@ ]/,'');
		     if(item.substr(0, tabStr.length).toLowerCase() == tabStr) {
			    tabtmp[tabtmp.length] = item;
			 }
		  }
		  if(!tabtmp[0]) {
		     for(var i in parent.fwindowlist.Witems) {
			    if(i.substr(0, tabStr.length).toLowerCase() == tabStr) {
               if(parent.fwindowlist.Witems[i].speak)
				      tabtmp[tabtmp.length] = i;
				}   
			 }
		  }
		  if(!tabtmp[0]) return false;
		  srcEl.value = srcEl.value.substr(0, tabIndex) + 
		        (tabIndex > 0 ? ' ' : '') + tabtmp[0] + (tabIndex == -1 ? ': ' : ' ');
		  tablen = tabtmp[0].length + (tabIndex == -1 ? 1 : 0);
		  tabpos = (tabIndex == -1 ? 0 : tabIndex + 1) + tablen;
		  tabinc = 1;
	   }
   }else if(keyCode == 38) { // UP
       if(!shistory[hispos]) {
	      if(document.myform["say"].value) hisadd();
		  hispos = shistory.length;
	   }
	   hispos--;
	   hisdo();
   }else if(keyCode == 40) { // DOWN
       if(!shistory[hispos]) {
	      if(document.myform["say"].value) hisadd();
		  document.myform["say"].value = '';
		  return false;
	   }
	   hispos++;
	   hisdo();
   }else if(event.altKey && !event.ctrlKey && keyCode > 47 && keyCode < 58) {
       var num = keyCode - 48;
	   if(num == 0) num = 10;

	   var name = parent.fwindowlist.witemchgnum(num);
	   if(!name) return false;
	   parent.fwindowlist.witemchg(name);
   }else{
       return true;
   }
   return false;
}
//-->
</script>
<link rel="stylesheet" href="$config->{script_login}?interface=ie&item=style&style=$cgi->{style}" />
</head>
<body onload="load()" onfocus="fns()" class="form-body">
<form name="myform" onSubmit="return cmd();" class="form-form">
<span id="nickname" class="form-nickname"></span>
<input type="text" class="form-say" name="say" autocomplete="off"
>
</form>
EOF

if($ENV{HTTP_USER_AGENT} !~ /Mac_PowerPC/) {
print <<EOF;
<span class="form-econtain">
<input type="button" class="form-expand" onclick="t(document.getElementById('extra'),this);" value="&lt;&lt;">
<span id="extra" class="form-extra">
<input type="button" class="form-boldbutton" value="B" onclick="append('\%B')">
<input type="button" class="form-boldbutton" value="_" onclick="append('\%U')">
EOF
for(sort {$a <=> $b} keys %colours) {
   print "<input type=\"button\" style=\"background: $colours{$_}\" value=\"&nbsp;&nbsp;\" onclick=\"append('\%C$_')\">\n";
}
print <<EOF;
</span>
</span>
EOF
}
print <<EOF;
</body>
</html>
EOF
}

1;
