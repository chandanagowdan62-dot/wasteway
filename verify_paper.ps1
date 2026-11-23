$docxPath = "C:\Users\chand\OneDrive\Documents\waste way\WasteWay_IEEE_Research_Paper_Final.docx"
$pdfPath = "C:\Users\chand\OneDrive\Documents\waste way\WasteWay_IEEE_Research_Paper_Final.pdf"

Write-Output "=================================================================="
Write-Output "WASTEWAY IEEE RESEARCH PAPER FINAL VERIFICATION REPORT"
Write-Output "=================================================================="

# 1. File Existence & Size
$docxItem = Get-Item $docxPath
$pdfItem = Get-Item $pdfPath
Write-Output "DOCX File: $($docxItem.FullName) ($([math]::Round($docxItem.Length / 1KB, 2)) KB)"
Write-Output "PDF File:  $($pdfItem.FullName) ($([math]::Round($pdfItem.Length / 1KB, 2)) KB)"

# 2. Page Count Verification
function Get-PdfPageCount($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $text = [System.Text.Encoding]::ASCII.GetString($bytes)
    $regex = [regex]'/Type\s*/Page[^s]'
    $matches = $regex.Matches($text)
    return $matches.Count
}

$pdfPages = Get-PdfPageCount $pdfPath
Write-Output "PDF Programmatic Page Count: $pdfPages"

$t = [Type]::GetTypeFromProgID("Word.Application")
$w = [Activator]::CreateInstance($t)
try {
    $w.Visible = $false
    $doc = $w.Documents.Open($docxPath)
    $wordPages = $doc.ComputeStatistics(2)
    $wordWords = $doc.ComputeStatistics(0)
    $wordParas = $doc.ComputeStatistics(4)
    $tableCount = $doc.Tables.Count
    $shapeCount = $doc.InlineShapes.Count
    
    Write-Output "Word Programmatic Page Count: $wordPages"
    Write-Output "Total Word Count:             $wordWords"
    Write-Output "Total Paragraphs:             $wordParas"
    Write-Output "Total Tables:                 $tableCount"
    Write-Output "Total Embedded Shapes/Images: $shapeCount"
    
    # 3. Content Inspection
    $docText = $doc.Content.Text
    
    $sections = @(
        "WasteWay: An AI-Powered Digital Waste Passport and Circularity Guidance System",
        "Chandana Gowda N",
        "Amrutha K",
        "Athmeeya B S",
        "HKBK College of Engineering",
        "Abstract—",
        "Keywords—",
        "I. INTRODUCTION",
        "II. RELATED WORK",
        "III. PROPOSED SYSTEM METHODOLOGY",
        "IV. IMPLEMENTATION",
        "V. RESULTS AND DISCUSSION",
        "VI. LIMITATIONS",
        "VII. CONCLUSION AND FUTURE SCOPE",
        "REFERENCES"
    )
    
    Write-Output "------------------------------------------------------------------"
    Write-Output "SECTION & METADATA VERIFICATION:"
    foreach ($sec in $sections) {
        $found = $docText.Contains($sec)
        $statusStr = if ($found) { "VERIFIED PRESENT" } else { "MISSING" }
        Write-Output ("  - " + $sec.PadRight(45) + ": " + $statusStr)
    }
    
    Write-Output "------------------------------------------------------------------"
    Write-Output "TABLE VERIFICATION:"
    $tablesFound = @(
        "TABLE I. COMPARATIVE ANALYSIS OF RELATED WORK",
        "TABLE II. COMPONENT IMPLEMENTATION AND VERIFICATION STATUS",
        "TABLE III. EMPIRICAL BENCHMARK PERFORMANCE"
    )
    foreach ($tbl in $tablesFound) {
        $found = $docText.Contains($tbl)
        $statusStr = if ($found) { "VERIFIED" } else { "MISSING" }
        Write-Output ("  - " + $tbl.PadRight(60) + ": " + $statusStr)
    }
    
    Write-Output "------------------------------------------------------------------"
    Write-Output "REFERENCE CITATION INTEGRITY CHECK [1] - [20]:"
    $allRefsPresent = $true
    for ($i = 1; $i -le 20; $i++) {
        $citation = "[$i]"
        if (-not $docText.Contains($citation)) {
            Write-Output "  * Warning: Reference $citation not found in text!"
            $allRefsPresent = $false
        }
    }
    if ($allRefsPresent) {
        Write-Output "  All 20 IEEE references [1] through [20] are cited and listed in the document."
    }
    
    $doc.Close($false)
} finally {
    $w.Quit()
}

Write-Output "=================================================================="
if ($pdfPages -eq 6 -and $wordPages -eq 6) {
    Write-Output "VERIFICATION SUCCESS: EXACTLY SIX PAGES CONFIRMED IN BOTH PDF AND DOCX!"
} else {
    Write-Output "VERIFICATION FAILURE: PAGE COUNT DOES NOT EQUAL 6!"
}
Write-Output "=================================================================="
