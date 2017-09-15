param( 
    [string] $remoteHostPart = “10.32.161.”,       ## enter IP Addresspart of HVCB NetBackplane
    [int] $port = 23,                              ## leave it unchanged
    [int] $stepping = 10,                          ## enter Voltage-Stepping
    [int] $karte = 1,                              ## enter first Card Number
    [string] $fpath = "C:\Users\Corell\Documents\Eigene Powershell Scripts\"     ## folder to save Data !!!MODIFY to correct Path!!!
     ) 


for ($ip = 101; $ip -lt 120; $ip++)
{
    $remoteHost = $remoteHostPart + $ip.ToString()
    
    ## Open the socket, and connect to the computer on the specified port 
    write-host “Connecting to $remoteHost on port $port” 
    $socket = new-object System.Net.Sockets.TcpClient($remoteHost, $port) 
    if($socket -eq $null) 
    { 
        return;
    } 

    write-host “Connected.`n” 

    $stream = $socket.GetStream() 
    $writer = new-object System.IO.StreamWriter($stream) 

    $buffer = new-object System.Byte[] 1024 
    $encoding = new-object System.Text.AsciiEncoding 

    start-sleep -m 2000

    # Set time on MCP
    $date = Get-Date
    $command = "time " + $date.Hour + " " + $date.Minute + " " + $date.Second + " "  + $date.Day + " " + $date.Month + " " + $date.Year
    $writer.WriteLine($command) 
    $writer.Flush()

    ## Allow data to buffer for a bit
    start-sleep -m 1000
    while($stream.DataAvailable)  
    {  
       $read = $stream.Read($buffer, 0, 1024)    
       write-host ($encoding.GetString($buffer, 0, $read-4))
    }

    start-sleep 2
    
    for ($level = 0; $level -le 4; $level++)
    {
        $card = [int]$karte + $level
        if ([int]$card -le 9)
        {
            $card = "00" + $card
        }
        elseif ([int]$karte -le 99)
        {
            $card = "0" + $card
        }
        $file = $fpath + "karte" + $card.ToString() + ".txt"
        out-file $file -InputObject "Sollwert,Date,Level,CH0,CH1,CH2,CH3,CH4,CH5,CH6,CH7" -Encoding ASCII
        
        for ($i = 1400; $i -le 1700; $i+=$stepping)
        {
            for ($dac = 0; $dac -le 7; $dac++)
            {
                $command = "SetVpmF " + $level +" " + $dac +" "+$i
            
                ## Write command to the remote host      
                $writer.WriteLine($command) 
                $writer.Flush() 
                ## Read all the data available from the stream, writing it to the 
                ## screen when done. 
                start-sleep -m 100
            }
            start-sleep 3
            while($stream.DataAvailable)  
            {  
               $read = $stream.Read($buffer, 0, 1024)    
            }
            $command = "read_adc csv2L " + $level
            
            ## Write command to the remote host      
            $writer.WriteLine($command) 
            $writer.Flush() 
            ## Read all the data available from the stream, writing it to the 
            ## screen when done. 
            start-sleep 3
            
            while($stream.DataAvailable)  
            {  
               $read = $stream.Read($buffer, 0, 1024)
               $str = $i.ToString() + "," + ($encoding.GetString($buffer, 0, $read-4))
               write-host $str 
               out-file $file -Append -InputObject $str -Encoding ASCII
            }
        }
    }

    $command = "quit"  
    $writer.WriteLine($command) 
    $writer.Flush() 
    ## Close the streams 
    $writer.Close() 
    $stream.Close()
    
    [int]$karte =  [int]$karte + 5
}