#!/bin/bash

# Define the output CSV file
ENDPOINTS="aws_endpoints.txt"
DATA_FILE="ping_data.csv"
MAX_ENTRIES=24
GRAPH_DIR="graphs"
WEBDIR="/var/www/html/aws/"

# Create or clear the data file
echo "Region Name,Region Code,Ping Time" > "$DATA_FILE"

# Create a directory for the graphs
mkdir -p "$GRAPH_DIR"

# Function to ping an endpoint and append results
ping_endpoint() {
    local region_name="$1"
    local region_code="$2"
    local endpoint="$3"
    
    ping_time=$(ping -c 4 "$endpoint" | grep 'min/avg/max/' | sed 's/.*= //g' | awk -F'/' '{print $1}')
    echo "$region_name,$region_code,$ping_time" >> "$DATA_FILE"
    
    # Ensure a .dat file for each region, indexed by line number in the .dat file
    index=$(( $(wc -l < "$GRAPH_DIR/${region_code}.dat" 2>/dev/null || echo 0) + 1 ))
    echo "$index,$ping_time" >> "$GRAPH_DIR/${region_code}.dat"
}

# Read the endpoints from the file and ping in parallel
while IFS=',' read -r region_name region_code endpoint; do
    ping_endpoint "$region_name" "$region_code" "$endpoint" &
done < $ENDPOINTS
wait # Wait for all pings to complete


echo "Response gathering completed"

echo "Generating combined plot"
# Current hour
current_hour=$(date +"%H")
start_hour=$(date +"%H" | sed 's/^0//')
x_end=$((start_hour + MAX_ENTRIES - 1))

# Generate hours for x-axis labels
x_labels=""
#for ((i=0; i<$MAX_ENTRIES; i++)); do
#    hour=$(( (10#$current_hour - i + 24) % 24 )) # wrap around after 23
#	echo "hour $hour"
#    x_labels="$x_labels $(printf '%02d' $hour)"
#done

x_labels=""
for ((i=0; i<$MAX_ENTRIES; i++)); do
    hour=$(( (10#$current_hour - (MAX_ENTRIES - i - 1) + 24) % 24 )) # Calculate hour for forward sequence
    x_labels="$x_labels \"$(printf '%02d' $hour)\" $i, " # Use $i for position
done
# Remove the trailing comma and space from x_labels
x_labels="${x_labels%, }"

rm graphs/*.png #make sure graphs are regenerated, if not there is a problem with gnuplat code
rm graphs/*indexed.dat #clean out temporary indexes from last run


# Add an index column to each data file to ensure continuous x-axis positions
for file in graphs/*.dat; do
    awk '{print NR-1 "," $0}' "$file" > "${file%.dat}_indexed.dat"
done

echo $x_labels

echo "Start the gnuplot block for the combined plot"
gnuplot <<-EOF
    set datafile separator ","
    set terminal png size 1000,800
    set output "graphs/all_regions.png"
    set title "Combined Response Times"
    set xlabel "Last 24 Hours"
    set ylabel "Response (ms)"
    set xtics ($x_labels) 
    set xrange [0:$((MAX_ENTRIES - 1))]  # Set the x range from 0 to MAX_ENTRIES - 1

    # Create the plot command
    plot for [file in system("ls graphs/*_indexed.dat")] file using 1:3 with lines title system("basename " . file . " .dat")


EOF



echo "Generate individual graphs using gnuplot from $DATA_FILE"
for region_code in $(tail -n +2 "$DATA_FILE" | cut -d',' -f2 "$ENDPOINTS" | sort | uniq); do
   	echo "Graphing $region_code"
gnuplot <<-EOF
    set datafile separator "," 
    set terminal png size 1000,800
    set output "graphs/${region_code}.png"
    set title "${region_code}Response Times"
    set xlabel "Last 24 Hours"
    set ylabel "Response (ms)"
    set xtics ($x_labels)
    set xrange [0:$((MAX_ENTRIES - 1))]  # Set the x range from 0 to MAX_ENTRIES - 1
       
        # Apply continuous offset in the x-axis
	#plot "$GRAPH_DIR/${region_code}.dat" using (int(\$1 - $start_hour) + 24 * (int(\$1 < $start_hour))-1):2 with lines title "$region_code"
    #plot "$GRAPH_DIR/${region_code}.dat" using (NR-1):2 with lines title "$region_code"
    plot "$GRAPH_DIR/${region_code}_indexed.dat" using 1:3 with lines title "$region_code"




EOF
done

# Generate HTML page with ping data and graphs
cat <<EOF > AZresponse.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AWS Response Report</title>
</head>
    <style>

        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 20px;
        }
        h1 {
            text-align: center;
            color: #333;
        }
        table {
            width: 50%;
            border-collapse: collapse;
            margin: 20px auto; /* Center the table */
            font-size: 0.6em; /* Further reduce font size */
        }
        th, td {
            padding: 2px; /* Reduce padding for smaller height */
            text-align: left;
        }
        th {
            background-color: #0073e6;
            color: white;
        }
        td {
            background-color: #f9f9f9;
        }
        tr:nth-child(even) td {
            background-color: #e6f7ff;
        }



        .image-container {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
        }
        .image-container img {
            width: 200px; /* Adjust to make images smaller */
            height: auto;
            border: 1px solid #ccc;
        }
    </style>
<body>
    <h1>AWS Region Response</h1>
    <table border="1">
        <tr>
            <th>Region Name</th>
            <th>Region Code</th>
            <th>Response Time AVG (ms)</th>
        </tr>
EOF

# Populate HTML table with data
while IFS=',' read -r region_name region_code ping_time; do
    echo "        <tr><td>$region_name</td><td>$region_code</td><td>$ping_time</td></tr>" >> AZresponse.html
done < <(tail -n +2 "$DATA_FILE")

cat <<EOF >> AZresponse.html
    </table>
    <h2>Graphs</h2>
	<img src="graphs/all_regions.png" alt="Graph for combinded.png)">
    <hr>
    <div class="image-container">
EOF

# Add graphs to HTML
for graph in "$GRAPH_DIR"/*.png; do
	echo "-> html $graph <-"
	if [ "$graph" != "graphs/all_regions.png" ]
		then
    	echo "<img src=\"$graph\" alt=\"Graph for $(basename "$graph" .png)\">" >> AZresponse.html
	fi
done

cat <<EOF >> AZresponse.html
</div>
</body>
</html>
EOF

rm AZresponse.png
rm AZresponse.jpg

wkhtmltoimage AZresponse.html AZresponse.png
wkhtmltoimage AZresponse.html AZresponse.jpg
cp -R graphs $WEBDIR
cp AZresponse.html $WEBDIR

cp AZresponse.png $WEBDIR
cp AZresponse.jpg $WEBDIR
