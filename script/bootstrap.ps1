

$jarCommands = Get-ChildItem 'C:\Program Files\Java' -Include "jar.exe" -Recurse
$jarCommand = $jarCommands[0]

if (-not (test-path $jarCommand))
{
    Write-Error "Could not find Java SDK jar.exe command"
    exit
}
else
{
    Write-Host "Using jar.exe from" $jarCommand
}


# Function from http://serverfault.com/questions/313015/trying-to-unzip-a-file-with-powershell
function Extract-Zip 
{ 
    param([string]$zipfilename, [string] $destination) 
    if(test-path($zipfilename)) 
    { 
        $shellApplication = new-object -com shell.application 
        $zipPackage = $shellApplication.NameSpace($zipfilename) 
        $destinationFolder = $shellApplication.NameSpace($destination) 
        $destinationFolder.CopyHere($zipPackage.Items()) 
    }
    else 
    {   
        Write-Error "Zip file:" $zipfilename "not found"
    }
} 

function New-Directory
{
    param([string]$dir)
    if (-not (test-path $dir))
    {
        New-Item $dir -ItemType Directory
    }
    return (Get-Item $dir)
}

$clojureZip = Join-Path (Get-Location) "clojure-1.4.0.zip"
$clojureDir = Join-Path (Get-Location) "clojure-1.4.0"
$libDir = Join-Path (Get-Location) "lib"

New-Directory $libDir
New-Directory $clojureDir
$targetDir = get-item $clojureDir 

echo "Fetching Clojure..."
Invoke-RestMethod -Uri  http://repo1.maven.org/maven2/org/clojure/clojure/1.4.0/clojure-1.4.0.zip -OutFile $clojureZip
Extract-Zip $clojureZip (Get-Location)

echo "Copying clojure-1.4.0/clojure-1.4.0.jar to lib/clojure.jar..."
Copy-Item $clojureDir/clojure-1.4.0.jar $libDir/clojure.jar

echo "Cleaning up Clojure directory..."
Remove-Item -Recurse $clojureDir

echo "Cleaning up Clojure archive..."
Remove-Item -Recurse $clojureZip


echo "Fetching Google Closure library..."
$closureLibrary = New-Directory "closure/library"
$closure = "closure-library-20120710-r2029.zip"
$closureUri = "http://closure-library.googlecode.com/files/" + $closure
$closureZip = Join-Path $closureLibrary $closure 

Invoke-RestMethod -Uri $closureUri -OutFile $closureZip
Extract-Zip $closureZip $closureLibrary

echo "Cleaning up Google Closure library archive..."
Remove-Item $closureZip



echo "Fetching Google Closure compiler..."
$compilerDirectory = New-Directory "compiler"
$compilerUri = "http://closure-compiler.googlecode.com/files/compiler-latest.zip"
$compilerZip = Join-Path $compilerDirectory "compiler-latest.zip"
Invoke-RestMethod -Uri $compilerUri -OutFile $compilerZip
Extract-Zip $compilerZip $compilerDirectory

echo "Cleaning up Google Closure compiler archive..."
rm $compilerZip

$compilerJar = Join-Path $compilerDirectory "compiler.jar"


echo "Building lib/goog.jar..."
echo "jar cf ./lib/goog.jar -C closure/library/closure/ goog"
& $jarCommand cf ./lib/goog.jar -C closure/library/closure/ goog

echo "Fetching Rhino..."
$rhinoUri = "http://ftp.mozilla.org/pub/mozilla.org/js/rhino1_7R3.zip"
$rhinoZip =  Join-Path (Get-Location) "rhino1_7R3.zip"
Invoke-RestMethod -Uri $rhinoUri -OutFile $rhinoZip
Extract-Zip $rhinoZip (Get-Location)


echo "Copying rhino1_7R3/js.jar to lib/js.jar..."
cp rhino1_7R3/js.jar lib/js.jar
echo "Cleaning up Rhino directory..."
Remove-Item -Recurse rhino1_7R3
echo "Cleaning up Rhino archive..."
Remove-Item $rhinoZip

echo "Copying closure/compiler/compiler.jar to lib/compiler.jar"
Copy-Item $compilerJar lib

echo "[Bootstrap Completed]"
