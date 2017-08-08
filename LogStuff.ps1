# Module level Variables
$DefaultSmtpServ = 'mail.server.com'

Function Initialize-Log {
    <#
    .SYNOPSIS
    Describe the function here
    .DESCRIPTION
    Describe the function in more detail
    .EXAMPLE
    Give an example of how to use it
    .EXAMPLE
    Give another example of how to use it
    .PARAMETER LogType
    The computer name to query. Just one.
    .PARAMETER LogPath
    The computer name to query. Just one.
    .PARAMETER logname
    The name of a file to write failed computer names to. Defaults to errors.txt.
    .PARAMETER NoClobber
    The computer name to query. Just one.
    #>
    [CmdletBinding()]
    Param (
        #[Parameter(Mandatory=$True,
        #           ParameterSetName="File")]
        #[ValidateSet("Text","EventLog","Email","Host")]
        #[string]$LogType,
		
        [Parameter(Mandatory=$True,
                   ParameterSetName="File")]
        [string]$LogPath,
        
        [Parameter(Mandatory=$True,
                   ParameterSetName="File")]
        [string]$LogName,

        [Parameter(Mandatory=$False,
                   ParameterSetName="File")]
        [switch]$NoClobber,

        [Parameter(Mandatory=$True,
                   ParameterSetName="Email")]
        [string[]]$MailTo,

        [Parameter(Mandatory=$True,
                   ParameterSetName="Email")]
        [string]$MailFrom,

        [Parameter(Mandatory=$True,
                   ParameterSetName="Email")]
        [string]$MailSubj,

        [Parameter(Mandatory=$False,
                   ParameterSetName="Email")]
        [Parameter(ParameterSetName="SmsText")]
        [string]$MailSmtpServ = $DefaultSmtpServ,

        [Parameter(Mandatory=$False,
                   ParameterSetName="Email")]
        [string[]]$Cc,

        [Parameter(Mandatory=$False,
                   ParameterSetName="Email")]
        [string[]]$Bcc,

        [Parameter(Mandatory=$False,
                   ParameterSetName="Email")]
        [string]$Attachment,

        [Parameter(Mandatory=$False,
                   ParameterSetName="Email")]
        [string]$Message,

        [Parameter(Mandatory=$False,
                   ParameterSetName="Email")]
        [switch]$SendMail,

        [Parameter(Mandatory=$True,
                    ParameterSetName="SmsText")]
        [ValidateLength(10)]
        [string]$SmsNumber,

        [Parameter(Mandatory=$True,
                    ParameterSetName="SmsText")]
        [ValidateSet('Alltel','Att','Boost','Cricket','MetroPCS','Nextel','Sprint','Tmobile','Verizon','Virgin')]
        [string]$SmsCarrier,

        [Parameter(Mandatory=$True,
                   ParameterSetName="SmsText")]
        [string]$SmsFrom,

        [Parameter(Mandatory=$True,
                   ParameterSetName="SmsText")]
        [ValidateLength(1,160)]
        [string]$SmsMessage,

        [Parameter(Mandatory=$False,
                   ParameterSetName="SmsText")]
        [switch]$SmsSend,

        [Parameter(Mandatory=$True,
                   ParameterSetName="EvLog")]
        [string]$EventLogName='Windows PowerShell',

        [Parameter(Mandatory=$True,
                   ParameterSetName="EvLog")]
        [string]$EventLogSource='Powershell',

        [Parameter(Mandatory=$True,
                   ParameterSetName="EvLog")]
        [ValidateSet('Information','Warning','Error')]
        [string]$EventType='Information',

        [Parameter(Mandatory=$True,
                   ParameterSetName="EvLog")]
        [int]$EventLogID,

        [Parameter(Mandatory=$False,
                   ParameterSetName="EvLog")]
        [string]$ComputerName=$env:COMPUTERNAME,

        [Parameter(Mandatory=$False,
                   ParameterSetName="EvLog")]
        [string]$EventMessage
    )

    Begin {}

    Process {

        Switch ($PSCmdlet.ParameterSetName){
            "File" {
                $LogFile = Join-Path -Path $LogPath -ChildPath $LogName
                If ((Test-Path $LogFile) -and (!($NoClobber))) {
                    Write-Verbose "File $LogFile exists and -NoClobbber was not specified, so delete the file"
                    Remove-Item -Path $LogFile -Confirm:$false -Force
                }
        
                If (!(Test-Path $LogFile)) {
                    Write-Verbose "File does not exist, creating $LogFile"
                    $null = New-Item -Path $LogPath -Name $LogName -ItemType File 
                }
        
                Write-Verbose 'Create a hashtable with the output info'
                $info = @{
                    'ID'=[guid]::NewGuid();
                    'Type'='File';
                    'Path'=$LogPath;
                    'Name'=$LogName;
                    'File'=$LogFile
                }
            }
            "Email" {
                Write-Verbose 'Create a hashtable with the output info'
                $info = @{
                    'ID'=[guid]::NewGuid();
                    'Type'='Email';
                    'To'=$MailTo;
                    'Cc'=$Cc;
                    "Bcc"=$Bcc;
                    'From'=$MailFrom;
                    'Subject'=$MailSubj;
                    'Message'=$Message;
                    'Attachment'=$Attachment;
                    'SmtpServer'=$MailSmtpServ
                }
                If ($SendMail) {
                    Write-Verbose 'SendMail initialized'
                    # Some validation here
                    # SendMail private function
                }
            }
            "SmsText" {
                $SmsTo = $SmsNumber
                Switch ($SmsCarrier) {
                    'Alltel' {$SmsTo += '@message.alltel.com'}
                    'Att' {$SmsTo += '@txt.att.net'}
                    'Boost' {$SmsTo += '@myboostmobile.com'}
                    'Cricket' {$SmsTo += '@sms.mycricket.com'}
                    'MetroPCS' {$SmsTo += '@mymetropcs.com'}
                    'Nextel' {$SmsTo += '@messaging.nextel.com'}
                    'Sprint' {$SmsTo += '@messaging.sprintpcs.com'}
                    'Tmobile' {$SmsTo += '@tmomail.net'}
                    'Verizon' {$SmsTo += '@vtext.com'}
                    'Virgin' {$SmsTo += '@vmobl.com'}
                }
                Write-Verbose 'Create a hashtable with the output info'
                $info = @{
                    'ID'=[guid]::NewGuid();
                    'Type'='SmsText';
                    'To'=$SmsTo;
                    'From'=$SmsFrom;
                    'Message'=$SmsMessage;
                    'SmtpServer'=$MailSmtpServ
                }
                If ($SmsSend) {
                    Write-Verbose 'SendMail initialized'
                    # Some validation here
                    # SendMail private function here
                    # I'm thinking I may just remove this and force use of the Send-Log function
                }
            }
            "EvLog" {
                Write-Verbose "Initialize EventlogEntry Object"
		        Write-Verbose "Tetst if EventLog  $EventLogName on $ComputerName exists"
                $EventLogExists = [System.Diagnostics.EventLog]::Exists($EventLogName, $ComputerName)
                Write-Verbose "Tetst if source $EventLogSource on $ComputerName exists"
                $EventLogSourceExists = [System.Diagnostics.EventLog]::SourceExists($EventLogSource, $ComputerName)
                Write-Verbose "Log Exists is $EventLogExists"
                Write-Verbose "Source Exists is $EventLogSourceExists"
                If (!($EventLogExists)) {
                    Write-Verbose "Creating $EventLogName Log"
                    [System.Diagnostics.EventLog]::new($EventLogName)
                }
                If (!($EventLogSourceExists)) {
                    Write-Verbose "Creating $EventLogSource Source"
                    [System.Diagnostics.EventLog]::CreateEventSource($EventLogSource,$EventLogName,$ComputerName)
                }
                Write-Verbose 'Create a hashtable with the output info'
                $info = @{
                    'ID'=[guid]::NewGuid();
                    'Type'='EvLog';
                    'EventLogName'=$EventLogName;
                    'EnentLogSource'=$EventLogSource;
                    'EventType'='';
                    'EventLogID'='';
                    'ComputerName'=$ComputerName;
                    'EventMessage'=''
                }
            }
        }
        Write-Verbose 'Write hashtable to PSObject'
        Write-Output (New-Object –Typename PSObject –Prop $info)
    }

    End {}
}
Function Write-Log{
    <#
    .SYNOPSIS
    Describe the function here
    .DESCRIPTION
    Describe the function in more detail
    .EXAMPLE
    Give an example of how to use it
    .EXAMPLE
    Give another example of how to use it
    .PARAMETER LogType
    The computer name to query. Just one.
    .PARAMETER LogPath
    The computer name to query. Just one.
    .PARAMETER logname
    The name of a file to write failed computer names to. Defaults to errors.txt.
    .PARAMETER NoClobber
    The computer name to query. Just one.
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [PSObject]$CustomLogObject,

        [Parameter(Mandatory=$True)]
        [string]$Message,

        [Parameter(Mandatory=$False)]
        [ValidateSet("Info","Warning","Error")]
        [string]$Type = 'Info'
    )

    Begin {}

    Process {
        Switch ($CustomLogObject.Type){
            File {
                $LogEntry = "$(Get-Date -Format s) [$($Type.ToUpper())] - $($Message)"
                $LogEntry | Out-File -FilePath $CustomLogObject.File -Encoding ascii -Append
            }
            Email {
                $LogEntry = "$(Get-Date -Format s) [$($Type.ToUpper())] - $($Message) `r`n"
                $CustomLogObject.Message += $LogEntry
            }
            Default {}
        }
    }

    End {}
}
Function Send-Log {
    <#
    .SYNOPSIS
    Describe the function here
    .DESCRIPTION
    Describe the function in more detail
    .EXAMPLE
    Give an example of how to use it
    .EXAMPLE
    Give another example of how to use it
    .PARAMETER computername
    The computer name to query. Just one.
    .PARAMETER logname
    The name of a file to write failed computer names to. Defaults to errors.txt.
    #>
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    Param (
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [PSObject]$CustomLogObject
    )

    Begin {}

    Process {
        Switch ($CustomLogObject.Type) {
            Email {
                Send-MailMessage -Attachments $CustomLogObject.Attachment -Bcc $CustomLogObject.Bcc -Body $CustomLogObject.Message -Cc $CustomLogObject.Cc -From $CustomLogObject.From -SmtpServer $CustomLogObject.SmtpServer -Subject $CustomLogObject.Subject -To $CustomLogObject.To
            }
            Default {}
        }
    }

    End {}
}


Function Edit-Log {
    <#
    .SYNOPSIS
    Describe the function here
    .DESCRIPTION
    Describe the function in more detail
    .EXAMPLE
    Give an example of how to use it
    .EXAMPLE
    Give another example of how to use it
    .PARAMETER computername
    The computer name to query. Just one.
    .PARAMETER logname
    The name of a file to write failed computer names to. Defaults to errors.txt.
    #>
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    Param (
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='What computer name would you like to target?')]
        [Alias('host')]
        [ValidateLength(3,30)]
        [string[]]$computername,
		
        [string]$logname = 'errors.txt'
    )

    Begin {}

    Process {
        # Edits the log object, all parameters same as init-log and optional
    }

    End {}
}