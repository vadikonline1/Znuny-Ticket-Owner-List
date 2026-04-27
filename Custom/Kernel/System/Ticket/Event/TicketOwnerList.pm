package Kernel::System::Ticket::Event::TicketOwnerList;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    for my $Needed (qw(Data Event Config UserID)) {
        return if !$Param{$Needed};
    }

    return 1 if $Param{Event} ne 'TicketOwnerUpdate';

    my $TicketID = $Param{Data}->{TicketID} || return;

    my $DynamicFieldName = $Param{Config}->{DynamicField} || return;

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
        Name => $DynamicFieldName,
    ) || return;

    return if $DynamicField->{ObjectType} ne 'Ticket';
    return if $DynamicField->{FieldType} ne 'Text';

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my @Owners = $TicketObject->TicketOwnerList(
        TicketID => $TicketID,
    );

    my @OwnerArray;
    for my $Owner (@Owners) {
        next if !$Owner->{UserFullname};
        push @OwnerArray, $Owner->{UserFullname};
    }

    my %Seen;
    @OwnerArray = grep { !$Seen{$_}++ } @OwnerArray;

    my $OwnerStrg = join(', ', @OwnerArray);

    $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $DynamicField,
        ObjectID           => $TicketID,
        Value              => $OwnerStrg,
        UserID             => $Param{UserID},
    );

    return 1;
}

1;