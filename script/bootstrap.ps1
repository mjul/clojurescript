# Check that the Java SDK "jar" tool is available
$jarCommand = Get-Command "[j]ar.exe"
if ((-not $jarCommand) -or -not (Test-Path $jarCommand)) 
{ 
    throw "could not find jar.exe, you need to install the Java SDK or add it to your PATH." 
}



function Get-Absolute-Path
{
    param([string] $file)
    if ([IO.Path]::IsPathRooted($file))
    {
        return $file
    }
    return ([IO.FileInfo] (Join-Path (Get-Location) $file)).FullName
}




# Function inspired by http://serverfault.com/questions/313015/trying-to-unzip-a-file-with-powershell
function Extract-Zip 
{ 
    param([string]$ZipFile, [string] $Target) 
    if(test-path($ZipFile)) 
    { 
        $absZip = Get-Absolute-Path $ZipFile
        $absTarget = Get-Absolute-Path $Target
        Write-Host ("Unzipping {0} to {1}..." -f $absZip, $absTarget)
        $shellApplication = new-object -com shell.application 
        $zipPackage = $shellApplication.NameSpace( $absZip )
        $destinationFolder = $shellApplication.NameSpace( $absTarget )
        $destinationFolder.CopyHere($zipPackage.Items()) 
    }
    else 
    {   
        throw ("Zip file: {0} not found" -f $ZipFile)
    }
} 

function New-Directory
{
    param([string]$Dir)
    if (-not (test-path $Dir))
    {
        New-Item $Dir -ItemType Directory
    }
    return (Get-Item $Dir)
}

function Download-Unzip
{
    param([string] $Uri, [string] $ZipFile, [string] $Target)
    Write-Host ("Downloading {0}..." -f $Uri)
    Invoke-RestMethod -Uri $Uri -OutFile $ZipFile
    Extract-Zip -ZipFile $ZipFile -Target $Target
}

$libDir = Join-Path (Get-Location) "lib"
New-Directory $libDir

# --------------------------------------------------------------

$clojureZip = Join-Path (Get-Location) "clojure-1.4.0.zip"
$clojureDir = Join-Path (Get-Location) "clojure-1.4.0"

Write-Host "Fetching Clojure..." -ForegroundColor Cyan
Download-Unzip -Uri http://repo1.maven.org/maven2/org/clojure/clojure/1.4.0/clojure-1.4.0.zip -ZipFile $clojureZip -Target .
Copy-Item .\clojure-1.4.0\clojure-1.4.0.jar (Join-Path $libDir clojure.jar)
echo "Cleaning up Clojure directory..."
Remove-Item -Recurse $clojureDir
echo "Cleaning up Clojure archive..."
Remove-Item -Recurse $clojureZip

# --------------------------------------------------------------

Write-Host "Fetching Google Closure library..." -ForegroundColor Cyan

$closureLibrary = New-Directory "closure/library"
$closure = "closure-library-20120710-r2029.zip"
$closureUri = "http://closure-library.googlecode.com/files/" + $closure
$closureZip = Join-Path $closureLibrary $closure 

Download-Unzip -Uri $closureUri -ZipFile $closureZip -Target $closureLibrary

Write-Host "Cleaning up Google Closure library archive..."
Remove-Item $closureZip

# --------------------------------------------------------------

Write-Host "Fetching Google Closure compiler..." -ForegroundColor Cyan
$compilerDirectory = New-Directory "compiler"
$compilerUri = "http://closure-compiler.googlecode.com/files/compiler-latest.zip"
$compilerZip = Join-Path $compilerDirectory "compiler-latest.zip"
$compilerJar = Join-Path $compilerDirectory "compiler.jar"

Download-Unzip -Uri $compilerUri -ZipFile $compilerZip -Target $compilerDirectory
Invoke-RestMethod -Uri $compilerUri -OutFile $compilerZip
Extract-Zip $compilerZip $compilerDirectory

Write-Host "Cleaning up Google Closure compiler archive..."
Remove-Item $compilerZip

Write-Host "Building lib/goog.jar..."
& $jarCommand cf (Join-Path $libDir goog.jar) -C (Join-Path $closureLibrary closure) goog

Copy-Item $compilerJar $libDir

# --------------------------------------------------------------

Write-Host "Fetching Rhino..." -ForegroundColor Cyan
$rhinoUri = "http://ftp.mozilla.org/pub/mozilla.org/js/rhino1_7R3.zip"
$rhinoZip =  Join-Path (Get-Location) "rhino1_7R3.zip"
$rhinoDir =  Join-Path (Get-Location) rhino1_7R3
Download-Unzip -Uri $rhinoUri -ZipFile $rhinoZip -Target .
Copy-Item (Join-Path $rhinoDir js.jar) (Join-Path $libDir js.jar)
Remove-Item -Recurse $rhinoDir
Remove-Item $rhinoZip

# --------------------------------------------------------------

Write-Host "[Bootstrap Completed]"
