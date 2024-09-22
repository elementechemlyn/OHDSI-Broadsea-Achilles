{{- $separator := "," -}}
{{- printf "Vulnerability ID%sPackage Name%sPackage Version%sSeverity%sDescription" $separator $separator $separator $separator -}}
{{- "\n" -}}
{{- range .Vulnerabilities }}
{{- printf "%s%s%s%s%s%s%s%s%s" .VulnerabilityID $separator .PkgName $separator .PkgVersion $separator .Severity $separator .Description }}
{{- "\n" -}}
{{- end }}
