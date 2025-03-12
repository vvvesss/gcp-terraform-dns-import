require 'csv'

# Fetch DNS records from gcloud
zone = "your-gcp-dns-zone-name"
dns_records = `gcloud dns record-sets list --zone="#{zone}" --format="csv(NAME,TYPE,TTL,DATA)"`
import_command = ""
# Parse CSV output
records = CSV.parse(dns_records, headers: true)
records.each do |record|
  if record["name"] && record["type"] && record["ttl"] && record["data"]
    puts "processing record #{record['name']}"
  else
    puts "skipping record #{record['name']} && #{record['type']} && #{record['ttl']} && #{record['data']}"
    next
  end
  name = record["name"].strip
  type = record["type"].strip
  ttl = record["ttl"].strip
  data = record["data"].strip # Some records may contain multiple values

  # Escape double quotes for TXT records
  if type == "TXT"
    data.gsub('"', '\\"')  # Properly escape Terraform TXT record format
  else
    data = "\"#{data}\""  # Wrap all non-TXT values in quotes
  end

  # Generate Terraform resource name
  resource_name = name.gsub(/[^a-zA-Z0-9]/, '_').downcase + "_#{type.downcase}"
  import_command += "terraform import google_dns_record_set.#{resource_name} \"projects/vaultody/managedZones/#{zone}/rrsets/#{name}/#{type}\"\n"

  # Generate Terraform resource content
  terraform_content = """
  resource \"google_dns_record_set\" \"#{resource_name}\" {
    name         = \"#{name}\"
    type         = \"#{type}\"
    ttl          = #{ttl}
    managed_zone = \"#{zone}\"

    rrdatas = [#{data}]
  }
  """

  # Special case for SRV records
  if type == "SRV"
    terraform_content = """
    resource \"google_dns_record_set\" \"#{resource_name}\" {
      name         = \"#{name}\"
      type         = \"#{type}\"
      ttl          = #{ttl}
      managed_zone = \"#{zone}\"
      rrdatas = [
    """
    data.gsub('"', '').split(",").each do |srv|
      terraform_content += """
      \"#{srv}\",
      """
    end    
    terraform_content += """
      ]
    }
    """
  end

  filename_import = "./import.sh"
  File.write(filename_import, import_command)

  # Write Terraform file
  filename = "#{name.gsub(/[^a-zA-Z0-9]/, "_").downcase}#{type}_.tf"
  File.write(filename, terraform_content)

  puts "Generated: #{filename}"
end
