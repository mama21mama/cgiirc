# $Id: Channel.pm,v 1.2 2002/03/17 00:56:51 dgl Exp $
package IRC::Channel;
use strict;
use IRC::UniqueHash;
use IRC::Util;
use IRC::Channel::Nick;
use IRC::Channel::Ban;

sub new {
   my $class = shift;
   my $self = bless {}, $class;
   %$self = @_;
   $self->{_nicks} = { };
   $self->{_bans} = { };
   tie %{$self->{_nicks}}, 'IRC::UniqueHash';
   return $self;
}

sub addnick {
   my($self,$nick,%nick) = @_;
   return 0 if exists $self->{_nicks}->{$nick};

   $self->{_nicks}->{$nick} = IRC::Channel::Nick->new(
       name => $nick,
	   op => defined $nick{op} ? $nick{op} : 0,
	   voice => defined $nick{voice} ? $nick{voice} : 0,
	   halfop => defined $nick{halfop} ? $nick{halfop} : 0
   );
}

sub delnick {
   my($self,$nick) = @_;
   return 0 unless exists $self->{_nicks}->{$nick};
   return delete($self->{_nicks}->{$nick});
}

sub chgnick {
  my($self,$nick,$newnick) = @_;
  return 0 unless exists $self->{_nicks}->{$nick};
  $self->{_nicks}->{$newnick} = $self->{_nicks}->{$nick};
  $self->{_nicks}->{$newnick}->{name} = $newnick;
  return $self->{_nicks}->{$newnick} if lc $newnick eq lc $nick;
  return delete($self->{_nicks}->{$nick});
}

sub nick {
   my($self,$nick) = @_;
   return 0 unless exists $self->{_nicks}->{$nick};
   return $self->{_nicks}->{$nick};
}

sub nicks {
   my($self) = @_;
   return keys %{$self->{_nicks}};
}

sub is_nick {
   my($self,$nick) = @_;
   return 1 if $self->{_nicks}->{$nick};
   0;
}

sub is_voice {
   my($self, $nick) = @_;
   return 1 if $self->{_nicks}->{$nick}->{voice};
   0;
}

sub is_op {
   my($self, $nick) = @_;
   return 1 if $self->{_nicks}->{$nick}->{op};
   0;
}

sub get_umode {
   my($self, $nick) = @_;
   if($self->{_nicks}->{$nick}->{op}) {
      return '@';
   }elsif($self->{_nicks}->{$nick}->{halfop}) {
      return '%';
   }elsif($self->{_nicks}->{$nick}->{voice}) {
      return '+';
   }else{
      return ' ';
   }
}

sub has_mode {
   my($self,$mode) = @_;
   return 1 if check_mode($self->{mode},$mode);
   0;
}

sub addban {
   my($self,$ban,%ban) = @_;
   return 0 if exists $self->{_bans}->{$ban};
   
   $self->{_bans}->{$ban} = IRC::Channel::Ban->new(
      setby => $ban{setby},
	  'time' => $ban{'time'},
   );
		 
}

sub delban {
   my($self,$ban) = @_;
	
   return 0 unless exists $self->{_bans}->{$ban};
   return delete($self->{_bans}->{$ban});	   
}

sub ban {
   my($self,$ban) = @_;

   return 0 unless exists $self->{_bans}->{$ban};
   return $self->{_bans}->{$ban};
}

sub bans {
  my($self) = @_;
  return keys %{$self->{_bans}};
}

sub is_banned {
   my($self,$host) = @_;
   for(keys %{$self->{_bans}}) {
      return 1 if match_mask($host,$_);
   }
   0;
}

1;
