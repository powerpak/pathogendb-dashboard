require 'date'
require 'sequel'
require 'open-uri'
require 'csv'
require 'cgi'

raise "FATAL: Configuration (config.yaml) did not load successfully" unless CONFIG

DB = Sequel.connect(CONFIG['msdw2_url'])

PATHOGENDB_ISOLATES_URL = "#{CONFIG['pathogendb']['base_url']}/tIsolates.php?PME_sys_fl=1&PME_sys_fm=0&PME_sys_qf6={{QUERY}}" + 
    '&PME_sys_sfn%5B0%5D=10&PME_sys_export=csv'

def msdw2_positive_blood_cultures(species)
  points = []
  prev_pt_ids = []
  (2009..2014).each do |year|
    (1..12).each do |month|
      point = {x: Date.new(year, month, 1).to_time.to_i}
      end_date = month < 12 ? Date.new(year, month + 1) : Date.new(year + 1, 1)
      new_pt_ids = DB[:trp_isolates]
        .join(:trp_cultures, :trp_cultures__id => :culture_id)
        .join(:trp_visits, :masked_visit_id => :masked_visit_id)
        .where(:order_code => "404-BLOOD CULTURE")
        .where(:specimen_collected_date => (Date.new(year, month)..end_date))
        .where(:species => /^#{species}/)
        .distinct(:trp_visits__masked_mrn)
        .exclude(:trp_visits__masked_mrn => prev_pt_ids)   # ONLY count each MRN once.
        .select_map(:trp_visits__masked_mrn)
      point[:y] = new_pt_ids.size
      points << point
      
      prev_pt_ids += new_pt_ids
    end
  end
  points
end

def pathogendb_positive_blood_cultures(species)
  url = PATHOGENDB_ISOLATES_URL.sub('{{QUERY}}', CGI::escape(species))
  mrans = {}
  counts = Hash.new(0)
  points = []
  thirty_days_ago = Date.today - 30
  within30 = 0
  fh = open(url, :http_basic_authentication => [CONFIG['pathogendb']['auth']['user'], CONFIG['pathogendb']['auth']['password']])
  
  # We can rely on rows in this CSV being sorted by collection date in ascending order.
  CSV.new(fh, :headers => :first_row, :col_sep => ';').each do |line|
    if (line["Source A"] == 'Blood' || line["Source B"] == 'Blood') && !mrans[line["MRAN"]]
      collection_date = Date.parse(line["Collection date"])
      counts[Date.new(collection_date.year, collection_date.month)] += 1
      within30 += 1 if collection_date >= thirty_days_ago
      mrans[line["MRAN"]] = true   # ONLY count each MRN once.
    end
  end
  counts.each do |k, v|
    points << {:x => k.to_time.to_i, :y => v}
  end
  [points, within30]
end

### Poll MSDW2 for historical data

SPECIES = {
  serratia: 'SERRATIA MARCESCENS',
  steno: 'STENOTROPHOMONAS',
  acinetobacter: 'ACINETOBACTER BAUM',
  staph: 'STAPHYLOCOCCUS AUREUS'
}

if !(DB.test_connection rescue false)
  puts "WARN: Could not connect to MSDW2 at #{CONFIG['msdw2_url']}, MSDW2 functions disabled"
elsif !CONFIG['pathogendb']['auth']['password']
  puts "WARN: No password supplied for PathogenDB, PathogenDB functions disabled"
else
  i = 2
  SPECIES.each do |species_short, species_long|
    SCHEDULER.every '1d', :first_in => "#{i}s" do
      pathogendb_positives, within30 = pathogendb_positive_blood_cultures(species_long)
      send_event("#{species_short}-incidence", 
          series: [
            msdw2_positive_blood_cultures(species_long),
            pathogendb_positives
          ],
          displayedValue: within30,
          moreinfo: within30 > 1 ? 'new cases in last 30d' : 'new case in last 30d'
        )
    end
    i += 2
  end
end