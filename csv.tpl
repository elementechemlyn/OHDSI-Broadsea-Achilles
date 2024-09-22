{{- $separator := "," -}}
# Vulnerability Database Version: {{ .VulnerabilityDBVersion }}
# Vulnerability Database Date: {{ .VulnerabilityDBDate }}

Vulnerability ID,Package Name,Package Version,Severity,Description
{{- range .Vulnerabilities }}
{{- printf "%s%s%s%s%s%s%s%s%s" .VulnerabilityID $separator .PkgName $separator .PkgVersion $separator .Severity $separator .Description }}
{{- "\n" -}}
{{- end }}

