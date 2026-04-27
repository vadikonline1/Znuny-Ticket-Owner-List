package Kernel::System::Ticket::Event::TicketOwnerList;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
);

sub new {
    my ( $Type, %Param ) = @_;
    my $Self = {};
    bless( $Self, $Type );
    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    # validate params
    for my $Needed (qw(Data Event Config UserID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    return 1 if $Param{Event} ne 'TicketOwnerUpdate';

    my $TicketID = $Param{Data}->{TicketID};
    if ( !$TicketID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need TicketID!",
        );
        return;
    }

    my $DynamicFieldName = $Param{Config}->{DynamicField};
    if ( !$DynamicFieldName ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "DynamicField not defined!",
        );
        return;
    }

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
        Name => $DynamicFieldName,
    );

    if (
        !$DynamicField
        || $DynamicField->{ObjectType} ne 'Ticket'
        || $DynamicField->{FieldType} ne 'Text'
    ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Invalid DynamicField configuration!",
        );
        return;
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my @Owners = $TicketObject->TicketOwnerList(
        TicketID => $TicketID,
    );

    my @OwnerArray;
    for my $Owner (@Owners) {
        next if !$Owner->{UserFullname};
        push @OwnerArray, $Owner->{UserFullname};
    }

    # remove duplicates but keep order
    my %Seen;
    @OwnerArray = grep { !$Seen{$_}++ } @OwnerArray;

    my $OwnerStrg = join(', ', @OwnerArray);

    $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $DynamicField,
        ObjectID           => $TicketID,
        Value              => $OwnerStrg,
        UserID             => $Param{UserID},
    );

    $LogObject->Log(
        Priority => 'notice',
        Message  => "Updated InvolvedOwner for Ticket $TicketID",
    );

    return 1;
}

1;
