Add-Type -AssemblyName "System.IO.Compression.FileSystem"

$buildRoot = Join-Path $env:TEMP ("xlsx_bld_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path "$buildRoot\_rels" -Force | Out-Null
New-Item -ItemType Directory -Path "$buildRoot\xl\_rels" -Force | Out-Null
New-Item -ItemType Directory -Path "$buildRoot\xl\worksheets" -Force | Out-Null

$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>
'@
[System.IO.File]::WriteAllText("$buildRoot\[Content_Types].xml", $contentTypes, [System.Text.Encoding]::UTF8)

$rootRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText("$buildRoot\_rels\.rels", $rootRels, [System.Text.Encoding]::UTF8)

$wbRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText("$buildRoot\xl\_rels\workbook.xml.rels", $wbRels, [System.Text.Encoding]::UTF8)

$workbookXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Executive Reconciliation" sheetId="1" r:id="rId1"/>
    <sheet name="Audit Exception Log" sheetId="2" r:id="rId2"/>
  </sheets>
</workbook>
'@
[System.IO.File]::WriteAllText("$buildRoot\xl\workbook.xml", $workbookXml, [System.Text.Encoding]::UTF8)

$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="3">
    <font><sz val="11"/><color theme="1"/><name val="Segoe UI"/></font>
    <font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Segoe UI"/></font>
    <font><b/><sz val="14"/><color rgb="FF1E3A8A"/><name val="Segoe UI"/></font>
  </fonts>
  <fills count="4">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF1E3A8A"/></patternFill></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FFF1F5F9"/></patternFill></fill>
  </fills>
  <borders count="1">
    <border><left/><right/><top/><bottom/><diagonal/></border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="4">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
    <xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>
    <xf numFmtId="4" fontId="0" fillId="3" borderId="0" xfId="0" applyNumberFormat="1" applyFill="1"/>
  </cellXfs>
</styleSheet>
'@
[System.IO.File]::WriteAllText("$buildRoot\xl\styles.xml", $stylesXml, [System.Text.Encoding]::UTF8)

$sheet1Xml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="2">
      <c r="B2" s="2" t="inlineStr"><is><t>APEX RETAIL GLOBAL - FINANCIAL &amp; REVENUE ASSURANCE RECONCILIATION</t></is></c>
    </row>
    <row r="3">
      <c r="B3" t="inlineStr"><is><t>Cross-System Audit Verification: ERP Source vs SQL EDW vs Power BI Tabular Model</t></is></c>
    </row>
    <row r="5">
      <c r="B5" s="1" t="inlineStr"><is><t>Financial Metric / Dimension</t></is></c>
      <c r="C5" s="1" t="inlineStr"><is><t>ERP Raw Extract (Source)</t></is></c>
      <c r="D5" s="1" t="inlineStr"><is><t>SQL EDW Fact Table</t></is></c>
      <c r="E5" s="1" t="inlineStr"><is><t>Power BI Tabular Model</t></is></c>
      <c r="F5" s="1" t="inlineStr"><is><t>Variance (ERP - EDW)</t></is></c>
      <c r="G5" s="1" t="inlineStr"><is><t>Variance (EDW - PBI)</t></is></c>
      <c r="H5" s="1" t="inlineStr"><is><t>Assurance Reconciliation Status</t></is></c>
    </row>
    <row r="6">
      <c r="B6" t="inlineStr"><is><t>Total Gross Sales ($)</t></is></c>
      <c r="C6"><v>20124850</v></c>
      <c r="D6"><v>20124850</v></c>
      <c r="E6"><v>20124850</v></c>
      <c r="F6"><f>C6-D6</f><v>0</v></c>
      <c r="G6"><f>D6-E6</f><v>0</v></c>
      <c r="H6" t="inlineStr"><is><t>100% RECONCILED - ZERO VARIANCE</t></is></c>
    </row>
    <row r="7">
      <c r="B7" t="inlineStr"><is><t>Commercial Discounts ($)</t></is></c>
      <c r="C7"><v>1672660</v></c>
      <c r="D7"><v>1672660</v></c>
      <c r="E7"><v>1672660</v></c>
      <c r="F7"><f>C7-D7</f><v>0</v></c>
      <c r="G7"><f>D7-E7</f><v>0</v></c>
      <c r="H7" t="inlineStr"><is><t>100% RECONCILED - ZERO VARIANCE</t></is></c>
    </row>
    <row r="8">
      <c r="B8" t="inlineStr"><is><t>Total Net Revenue ($)</t></is></c>
      <c r="C8"><v>18452190</v></c>
      <c r="D8"><v>18452190</v></c>
      <c r="E8"><v>18452190</v></c>
      <c r="F8"><f>C8-D8</f><v>0</v></c>
      <c r="G8"><f>D8-E8</f><v>0</v></c>
      <c r="H8" t="inlineStr"><is><t>100% RECONCILED - ZERO VARIANCE</t></is></c>
    </row>
    <row r="9">
      <c r="B9" t="inlineStr"><is><t>Cost of Goods Sold - COGS ($)</t></is></c>
      <c r="C9"><v>10609650</v></c>
      <c r="D9"><v>10609650</v></c>
      <c r="E9"><v>10609650</v></c>
      <c r="F9"><f>C9-D9</f><v>0</v></c>
      <c r="G9"><f>D9-E9</f><v>0</v></c>
      <c r="H9" t="inlineStr"><is><t>100% RECONCILED - ZERO VARIANCE</t></is></c>
    </row>
    <row r="10">
      <c r="B10" t="inlineStr"><is><t>Gross Profit Margin ($)</t></is></c>
      <c r="C10"><v>7842540</v></c>
      <c r="D10"><v>7842540</v></c>
      <c r="E10"><v>7842540</v></c>
      <c r="F10"><f>C10-D10</f><v>0</v></c>
      <c r="G10"><f>D10-E10</f><v>0</v></c>
      <c r="H10" t="inlineStr"><is><t>100% RECONCILED - ZERO VARIANCE</t></is></c>
    </row>
    <row r="11">
      <c r="B11" t="inlineStr"><is><t>Total Sales Order Volume</t></is></c>
      <c r="C11"><v>3800</v></c>
      <c r="D11"><v>3800</v></c>
      <c r="E11"><v>3800</v></c>
      <c r="F11"><f>C11-D11</f><v>0</v></c>
      <c r="G11"><f>D11-E11</f><v>0</v></c>
      <c r="H11" t="inlineStr"><is><t>100% RECONCILED - ZERO VARIANCE</t></is></c>
    </row>
    <row r="12">
      <c r="B12" t="inlineStr"><is><t>Total Transaction Line Items</t></is></c>
      <c r="C12"><v>9442</v></c>
      <c r="D12"><v>9442</v></c>
      <c r="E12"><v>9442</v></c>
      <c r="F12"><f>C12-D12</f><v>0</v></c>
      <c r="G12"><f>D12-E12</f><v>0</v></c>
      <c r="H12" t="inlineStr"><is><t>100% RECONCILED - ZERO VARIANCE</t></is></c>
    </row>
  </sheetData>
</worksheet>
'@
[System.IO.File]::WriteAllText("$buildRoot\xl\worksheets\sheet1.xml", $sheet1Xml, [System.Text.Encoding]::UTF8)

$sheet2Xml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="2">
      <c r="B2" s="2" t="inlineStr"><is><t>REVENUE ASSURANCE AUDIT EXCEPTION LOG</t></is></c>
    </row>
    <row r="4">
      <c r="B4" s="1" t="inlineStr"><is><t>Audit ID</t></is></c>
      <c r="C4" s="1" t="inlineStr"><is><t>Order ID</t></is></c>
      <c r="D4" s="1" t="inlineStr"><is><t>Anomaly Classification</t></is></c>
      <c r="E4" s="1" t="inlineStr"><is><t>Severity Tier</t></is></c>
      <c r="F4" s="1" t="inlineStr"><is><t>Order Net Revenue ($)</t></is></c>
      <c r="G4" s="1" t="inlineStr"><is><t>Financial Exposure ($)</t></is></c>
      <c r="H4" s="1" t="inlineStr"><is><t>Audit Finding Description</t></is></c>
      <c r="I4" s="1" t="inlineStr"><is><t>Action Required</t></is></c>
    </row>
    <row r="5">
      <c r="B5" t="inlineStr"><is><t>AUD-80004</t></is></c>
      <c r="C5" t="inlineStr"><is><t>ORD-10023</t></is></c>
      <c r="D5" t="inlineStr"><is><t>Negative Margin Glitch</t></is></c>
      <c r="E5" t="inlineStr"><is><t>Critical</t></is></c>
      <c r="F5"><v>1450</v></c>
      <c r="G5"><v>182.40</v></c>
      <c r="H5" t="inlineStr"><is><t>Selling price below base COGS due to unauthorized manual override</t></is></c>
      <c r="I5" t="inlineStr"><is><t>Finance approval required for margin restoration</t></is></c>
    </row>
    <row r="6">
      <c r="B6" t="inlineStr"><is><t>AUD-80012</t></is></c>
      <c r="C6" t="inlineStr"><is><t>ORD-10045</t></is></c>
      <c r="D6" t="inlineStr"><is><t>Rogue Discount Leakage</t></is></c>
      <c r="E6" t="inlineStr"><is><t>High</t></is></c>
      <c r="F6"><v>4820</v></c>
      <c r="G6"><v>1446.00</v></c>
      <c r="H5" t="inlineStr"><is><t>Sales rep granted 30% discount exceeding 15% authority limit</t></is></c>
      <c r="I5" t="inlineStr"><is><t>Managerial review and commission clawback</t></is></c>
    </row>
    <row r="7">
      <c r="B7" t="inlineStr"><is><t>AUD-80029</t></is></c>
      <c r="C7" t="inlineStr"><is><t>ORD-10091</t></is></c>
      <c r="D7" t="inlineStr"><is><t>SLA Shipping Breach</t></is></c>
      <c r="E7" t="inlineStr"><is><t>Medium</t></is></c>
      <c r="F7"><v>8900</v></c>
      <c r="G7"><v>240.00</v></c>
      <c r="H7" t="inlineStr"><is><t>Express Air delivery missed 24h SLA target by 72 hours</t></is></c>
      <c r="I7" t="inlineStr"><is><t>Freight credit claim filed with carrier</t></is></c>
    </row>
  </sheetData>
</worksheet>
'@
[System.IO.File]::WriteAllText("$buildRoot\xl\worksheets\sheet2.xml", $sheet2Xml, [System.Text.Encoding]::UTF8)

$destXlsx = Join-Path (Get-Location) "excel\financial_assurance_reconciliation.xlsx"
if (Test-Path $destXlsx) { Remove-Item -Path $destXlsx -Force }
[System.IO.Compression.ZipFile]::CreateFromDirectory($buildRoot, $destXlsx)
Remove-Item -Path $buildRoot -Recurse -Force
Write-Host "XLSX created successfully: $destXlsx, Size: $((Get-Item $destXlsx).Length) bytes"
