require 'date'
require 'sequel'
require 'open-uri'
require 'csv'
require 'cgi'

raise "FATAL: Configuration (config.yaml) did not load successfully" unless CONFIG

DB = Sequel.connect(CONFIG['msdw2_url'])

CDIFFDB_ISOLATES_URL = "#{CONFIG['cdiffr01']['csv_url']}"


def cdiff_room_count(room)
  url = CDIFFDB_ISOLATES_URL
  mrans = {}
  since_collection = Hash.new(0)
  points = []
  today = Date.today
  fh = open(url, :http_basic_authentication => [CONFIG['pathogendb']['auth']['user'], CONFIG['pathogendb']['auth']['password']])

  total = 0
  patient_index = Hash.new(0)
  # We can rely on rows in this CSV being sorted by collection date in ascending order.
  counter = 0
  CSV.new(fh, :headers => :first_row, :col_sep => ';').each do |line|
  	if (line["Location"].to_s == room.to_s)
		  erap_id = line["eRAP ID"]
		  loc = line["Location"] 
		  collection_date = Date.parse(line["Scan date"].to_s)
      if !(patient_index.has_key?(erap_id))
        counter += 1
        patient_index[erap_id] = counter
      end
      since_collection[patient_index[erap_id]] = (today - collection_date).to_f
    end
  end
  p patient_index
  since_collection.each do |k, v|
    points << {:x => k, :y => v}
  end
  [points, total]
end

ICUS = {
  SICU: 'SICU',
  NSIC: 'NSICU',
  CSIU: 'CSICU',
  MICU: 'MICU'
}
if !CONFIG['pathogendb']['auth']['password']
  puts "WARN: No password supplied for PathogenDB, PathogenDB functions disabled"
end
if true
  i = 2
  ICUS.each do |room_short, room_long|
    SCHEDULER.every '1d', :first_in => "#{i}s" do
      since_collections, total = cdiff_room_count(room_long)
      p since_collections
      send_event("#{room_short}", 
          series: [
            [],
            since_collections
          ],
          displayedValue: total,
          moreinfo: total > 1 ? 'new cases in last 30d' : 'new case in last 30d'
        )
    end
    i += 2
  end
end