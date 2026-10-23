"""Hand-curated transit network: KIIT inter-campus links and CRUT Mo Bus routes.

Sources
- KIIT: student field research published at
  https://www.codedex.io/api/builds/by-slug/VPIrDIznhM96nncySq3K/index.html
  (38 two-way bus/shuttle links between 22 campuses; no timetables: vehicles
  leave when full, 2 to 30+ minutes).
- Mo Bus: CRUT network map, MO_BUS_Full_Network_Final_1.pdf (repo root).
  Stop sequences were transcribed from the schematic; minor stops between
  the listed ones are omitted. The map carries no timetable.

Edit this file, then run `python tool/build_network.py` to regenerate
assets/network/network.json.
"""

# ---------------------------------------------------------------- KIIT

# Campus coordinates. Only Campus 3, 6 and 15 are named in OpenStreetMap; the
# rest are placed by hand from the campus layout and must be verified on site.
CAMPUSES = {
    "C1": ("Campus 1 (Koel)", 20.3497, 85.8229, True),
    "C2": ("Campus 2 (Kolab)", 20.3550, 85.8178, True),
    "C3": ("Campus 3 (Kathajodi)", 20.35324, 85.81712, False),
    "C4": ("Campus 4", 20.3540, 85.8188, True),
    "C5": ("Campus 5", 20.3528, 85.8142, True),
    "C6": ("Campus 6 (Kosi)", 20.35307, 85.82015, False),
    "C7": ("Campus 7", 20.3502, 85.8210, True),
    "C8": ("Campus 8", 20.3517, 85.8195, True),
    "C9": ("Campus 9", 20.3506, 85.8128, True),
    "C10": ("Campus 10", 20.3489, 85.8172, True),
    "C11": ("Campus 11 (Kundali)", 20.3610, 85.8235, True),
    "C12": ("Campus 12 (Kodoor)", 20.3556, 85.8203, True),
    "C13": ("Campus 13 (Karmansha)", 20.3566, 85.8186, True),
    "C14": ("Campus 14 (Kaladan)", 20.3559, 85.8156, True),
    "C15": ("Campus 15 (Kallayi)", 20.34826, 85.81594, False),
    "C16": ("Campus 16 (Kangsabati, Law)", 20.3622, 85.8205, True),
    "C17": ("Campus 17", 20.3496, 85.8195, True),
    "C18": ("Campus 18", 20.3582, 85.8218, True),
    "C19": ("Campus 19", 20.3478, 85.8185, True),
    "C20": ("Campus 20 (Knowledge Tower)", 20.3530, 85.8245, True),
    "C22": ("Campus 22", 20.3524, 85.8256, True),
    "C25": ("Campus 25 (CSE)", 20.3645, 85.8170, True),
}

# (id, mode, path, source campus where vehicles start)
KIIT_ROUTES = [
    ("B-1", "bus", ["C2", "C3", "C4"], "C2"),
    ("B-2", "bus", ["C9", "C5"], "C5"),
    ("B-3", "bus", ["C4", "C6"], "C6"),
    ("B-4", "bus", ["C2", "C6"], "C6"),
    ("S-1", "shuttle", ["C2", "C6"], "C6"),
    ("B-5", "bus", ["C2", "C7"], "C7"),
    ("B-6", "bus", ["C3", "C7"], "C7"),
    ("B-7", "bus", ["C2", "C4", "C8"], "C8"),
    ("B-8", "bus", ["C3", "C8"], "C8"),
    ("S-2", "shuttle", ["C6", "C8"], "C8"),
    ("B-9", "bus", ["C5", "C9"], "C9"),
    ("S-3", "shuttle", ["C5", "C9"], "C9"),
    ("B-10", "bus", ["C6", "C12"], "C12"),
    ("B-11", "bus", ["C2", "C4", "C12"], "C12"),
    ("B-12", "bus", ["C3", "C12"], "C12"),
    ("B-13", "bus", ["C12", "C13"], "C13"),
    ("B-14", "bus", ["C6", "C13"], "C13"),
    ("S-4", "shuttle", ["C13", "C14"], "C14"),
    ("B-15", "bus", ["C6", "C8", "C15"], "C15"),
    ("B-16", "bus", ["C3", "C15"], "C15"),
    ("S-5", "shuttle", ["C3", "C15"], "C15"),
    ("S-6", "shuttle", ["C8", "C15"], "C15"),
    ("S-7", "shuttle", ["C6", "C15"], "C15"),
    ("S-8", "shuttle", ["C12", "C15"], "C15"),
    ("B-17", "bus", ["C4", "C17"], "C17"),
    ("S-9", "shuttle", ["C7", "C17"], "C17"),
    ("S-10", "shuttle", ["C6", "C2", "C17"], "C17"),
    ("S-11", "shuttle", ["C17", "C15"], "C17"),
    ("S-12", "shuttle", ["C3", "C17"], "C17"),
    ("S-13", "shuttle", ["C10", "C17"], "C17"),
    ("S-14", "shuttle", ["C12", "C18"], "C18"),
    ("B-18", "bus", ["C2", "C3", "C4", "C20"], "C20"),
    ("B-19", "bus", ["C17", "C20"], "C20"),
    ("B-20", "bus", ["C14", "C20"], "C20"),
    ("B-21", "bus", ["C5", "C20"], "C20"),
    ("B-22", "bus", ["C17", "C2", "C6", "C20"], "C22"),
    ("B-23", "bus", ["C3", "C20", "C14", "C13", "C25"], "C25"),
    ("S-15", "shuttle", ["C14", "C25"], "C25"),
]

# ---------------------------------------------------------------- Mo Bus

# Stops outside Bhubaneswar, used to steer geocoding.
AREA = {}
for n in [
    "Biju Patnaik Park", "State Bank Square", "Justice Square", "Saraswati Sishu Mandir", "Raj Kishore Marg",
    "CDA 9 Market Square", "CDA 6 Park", "Eye Hospital Square", "Sati Choura Square", "Dagarpada Road",
    "Judicial Academy", "Barabati Stadium", "Baliyatra Ground", "Deer Park", "Shifa Hospital",
    "Police Signal Traffic School", "Chahata Ghata", "Bidanasi", "Krushak Bazaar", "Sishu Bhawan (Cuttack)",
    "High Court Road", "Cuttack Sai Temple", "Puri Ghat PS", "City College", "Badambadi Square",
    "Khannagar Traffic", "Badambadi Bus Stand", "Pala Mandap", "Arundoya Market", "Nisamani Talkies", "Link Road",
    "Samrat Cinema", "OMP Square", "Gandarpur", "Shikharpur", "Jagatpur", "Khapuria Square",
    "Gopalpur Railway Station", "Balikuda", "Kunheipada", "Trisulia Square", "Madhuban", "Bachhipur",
    "Barang PS", "Barang",
]:
    AREA[n] = "Cuttack"
for n in [
    "Khordha Bypass Square", "Khordha New Bus Stand", "DRDA", "BSF Battalion Camp", "Padanpur", "NISER", "IIT Road",
    "Block Square", "Haribana Square", "Jatani Municipal Council", "Jatani PS", "Khordha Road Station",
    "Sayeed Memorial Hospital", "Nilakantheswar Square", "Kudiary High School", "Baba Somanatha Square",
    "Pitapalli Square", "Gangapada", "Jatani Gate", "Bhuasuni Temple", "Janla Medical", "Janla Post Office",
]:
    AREA[n] = "Khordha"
for n in ["Satasankha", "Sakhigopal", "Chandanpur", "Malatipatpur", "Puri Bus Stand"]:
    AREA[n] = "Puri"
for n in [
    "Pipili Bypass", "Pipili Nimapada Square", "Nimapada Bus Stand", "Gop Market", "Gop PS", "Begunia",
    "Sareda", "Junei", "Madipur Chhak", "Konark PS", "Sun Temple Konark", "Konark",
    "Jaishpatna Chowk", "Gobardhanpur", "Gudia Pokhari Square",
]:
    AREA[n] = "Puri district"

# Known anchor coordinates (lat, lng) that override geocoding.
FIXED = {
    "Bhubaneswar Railway Station": (20.2667, 85.8434),
    "Biju Patnaik International Airport": (20.2526, 85.8179),
    "Jaydev Vihar Square": (20.29532, 85.82484),
    "Fire Station Square": (20.27977, 85.79919),
    "KIIT Square": (20.35490, 85.81870),
    "Konark": (19.8876, 86.0945),
    "Sun Temple Konark": (19.8877, 86.0946),
    "Puri Bus Stand": (19.8096, 85.8341),
    "AIIMS": (20.2312, 85.77513),
    "Lingaraj Temple": (20.2382, 85.8338),
}

# Terminals no geocoder knows; placed by hand and flagged approximate.
FIXED_APPROX = {
    "Ranasinghpur": (20.2365, 85.7975),
    "Jadupur": (20.2335, 85.7905),
    "Chakeisiani": (20.3075, 85.8690),
    "Trident Galaxy": (20.2585, 85.7590),
    "K9 B": (20.2470, 85.7700),
    "Chatabar": (20.2440, 85.6650),
    "Baramunda ISBT": (20.2735, 85.7880),
    # Major junctions the geocoders don't index; anchor interpolation of nearby stops.
    "Vanivihar Square": (20.2963, 85.8402),
    "Satsang Vihar": (20.2963, 85.8475),
    "Raj Mahal Square": (20.2618, 85.8392),
    "Kalinga Hospital Square": (20.3170, 85.8205),
    "Rail Sadan": (20.3215, 85.8205),
    "Omfed Square": (20.3248, 85.8210),
    "New Airport Square": (20.2622, 85.8210),
    "Uttara Square": (20.2190, 85.8540),
    "Alu Godam": (20.2430, 85.7800),
    "Laxmi Sagar Square": (20.2680, 85.8550),
    "Pipili Nimapada Square": (20.1140, 85.8330),
    "OMP Square": (20.4800, 85.8820),
    "Sai Temple": (20.2425, 85.8470),  # Old Town, not the one at Nandankanan
}

NH_SOUTH = [  # Rasulgarh -> Link Road (Cuttack) along NH-16
    "Rasulgarh Square", "Palasuni", "Saptasati Temple", "Hi-Tech Hospital Square", "Hanspal Square",
    "Puri Canal Road", "Highway Honda", "Utkal Heights", "Pahala", "Apex College", "Nakhara Square", "Bamphakuda",
    "Telenga Pentha", "Delta Gada", "Pratap Nagari", "Bhanpur", "Balikuda", "Gopalpur Railway Station",
    "Khapuria Square", "Link Road",
]
CUTTACK_EAST = [  # Link Road -> Judicial Academy
    "Link Road", "Nisamani Talkies", "Arundoya Market", "Pala Mandap", "Badambadi Bus Stand", "Badambadi Square",
    "City College", "Puri Ghat PS", "Cuttack Sai Temple", "High Court Road", "Sishu Bhawan (Cuttack)",
    "Judicial Academy",
]
CUTTACK_WEST = [  # Judicial Academy -> Biju Patnaik Park
    "Judicial Academy", "Dagarpada Road", "Sati Choura Square", "Eye Hospital Square", "CDA 6 Park",
    "CDA 9 Market Square", "Raj Kishore Marg", "Saraswati Sishu Mandir", "Justice Square", "State Bank Square",
    "Biju Patnaik Park",
]
NANDANKANAN_RD = [  # KIIT Square -> Judicial Academy
    "KIIT Square", "Shikharchandi Vihar", "Nandan Vihar", "Mani Tribhuvan", "Royal Lagoon", "Raghunathpur",
    "Raghunathpur Village", "Nandankanan", "Barang", "Barang PS", "Bachhipur", "Madhuban", "Trisulia Square",
    "Kunheipada", "Judicial Academy",
]
KALINGA_HOSP_TO_JAYDEV = [
    "Kalinga Hospital Square", "Fortune Tower", "Xavier Square", "Janata Maidan", "Mayfair Road", "Pal Heights",
    "Jaydev Vihar Square",
]
DAMANA_TO_KALINGA_HOSP = ["Damana Square", "Niladri Vihar Square", "Omfed Square", "Rail Sadan", "Kalinga Hospital Square"]
PATIA_TO_DAMANA = ["Patia Square", "Chandrasekharpur PS", "Damana Square"]
KIIT_TO_INFOCITY = [
    "KIIT Square", "KIIT Campus Stop", "KIMS Hospital", "Shikharchandi", "Silicon College", "DLF Cybercity",
    "Infocity Square",
]
INFOCITY_TO_DAMANA = ["Infocity Square", "Trident College", "Sai Enclave", "Sailashree Vihar Square", "Damana Haat", "Damana Square"]
KALINGA_HOSP_TO_ACHARYA = [
    "Kalinga Hospital Square", "Press Square", "Sainik School Square", "Apollo Hospital", "Utkal University Gate-4",
    "Acharya Vihar Square",
]
ACHARYA_TO_AG = [
    "Acharya Vihar Square", "Ananda Bazaar", "Nicco Park Square", "Rotary Bhavan", "Housing Board Square",
    "Keshari Talkies", "Rabindra Mandap", "Secretariat", "AG Square",
]
TRUNK_WEST = ["Jaydev Vihar Square", "IMMT", "Acharya Vihar Square", "Vanivihar Square"]
TRUNK_EAST = ["Vanivihar Square", "Satsang Vihar", "VSS Nagar Road", "Rasulgarh Square"]
VANIVIHAR_TO_STATION = [
    "Vanivihar Square", "RD Women's College", "Rupali Square", "Maharshi College Square", "Satya Nagar",
    "Satya Nagar Square", "Ram Mandir", "Sriya Square", "Master Canteen", "Bhubaneswar Railway Station",
]
DIAGONAL = [  # Jaydev Vihar -> Fire Station Square
    "Jaydev Vihar Square", "Nabard", "Iskcon Temple", "Nayapalli", "CRPF Square", "Gopabandhu Nagar",
    "Fire Station Square",
]
FIRE_TO_ALU_GODAM = [
    "Fire Station Square", "Rajdhani College", "Baramunda", "Khandagiri Square", "Kolathia", "Aiginia", "Alu Godam",
]
FIRE_TO_OUAT = ["Fire Station Square", "Vivekanand Hospital", "Delta Square", "Satabdi Nagar", "City Women's College", "OUAT Square"]
OUAT_TO_AG = ["OUAT Square", "Siripur Market", "Gopabandhu Square", "Surya Nagar", "Governor House Square", "AG Square"]
AIRPORT_TO_AG = ["Biju Patnaik International Airport", "New Airport Square", "Capital Hospital", "AG Square"]
AG_TO_JAYDEV_VIA_STADIUM = [
    "AG Square", "Bhubaneswar Club", "Nautala", "Power House Square", "Sail Office", "Shastri Nagar Square",
    "The World", "Kalinga Stadium Gate-2", "Kalinga Stadium Gate-8", "Jaydev Vihar Square",
]
STATION_TO_JAYDEV_VIA_STADIUM = [
    "Bhubaneswar Railway Station", "Master Canteen", "Exhibition Ground", "AG Colony", "The World",
    "Kalinga Stadium Gate-2", "Kalinga Stadium Gate-8", "Jaydev Vihar Square",
]
STATION_TO_RAJMAHAL = ["Bhubaneswar Railway Station", "Master Canteen", "Raj Mahal Square"]
RAJMAHAL_TO_RAVI = [
    "Raj Mahal Square", "Kalpana Square", "State Museum", "BJB College", "NCC Canteen", "Shree Hospital",
    "Ravi Talkies Square",
]
RAVI_TO_UTTARA = [
    "Ravi Talkies Square", "Kedar Gouri Temple", "Gouri Nagar", "Lingaraj Temple Road", "Samantarapur", "Nuagaon",
    "Sishupalgarh", "Lingipur", "Sri Sri Borda Hospital", "Nathapur", "Dhauli Square", "Uttara Square",
]
UTTARA_TO_PIPILI = [
    "Uttara Square", "CIFA", "KEC", "Gudia Pokhari Square", "Gobardhanpur", "Jaishpatna Chowk", "Pipili Bypass",
    "Pipili Nimapada Square",
]
PIPILI_TO_PURI = ["Pipili Nimapada Square", "Satasankha", "Sakhigopal", "Chandanpur", "Malatipatpur", "Puri Bus Stand"]
RASULGARH_TO_KALPANA = [
    "Rasulgarh Square", "Rasulgarh Market", "Bomikhal", "Ekamra Talkies", "Jharpada", "Yatri Nivas",
    "Laxmi Sagar Square", "Old Station Bazaar", "Sabarashi Lane", "Kalpana Square",
]
RAJMAHAL_TO_LINGARAJ_STN = [
    "Raj Mahal Square", "Bapuji Nagar", "Sishu Bhawan Square", "Forest Park", "Old Airport Square", "Naveen Nivas",
    "Palaspalli", "Poonama Flyover", "Bhimatangi", "Ekamra College", "Lingaraj Station",
]
ALU_GODAM_TO_KHORDHA = [
    "Alu Godam", "Patrapada", "K9", "Kalinga Vihar Square", "Tamando", "Gohiria Square", "Retang Road Square",
    "Janla Post Office", "Janla Medical", "Bhuasuni Temple", "Jatani Gate", "Gangapada", "Pitapalli Square",
    "Khordha Bypass Square", "DRDA", "Khordha New Bus Stand",
]
KHANDAGIRI_TO_DUMDUMA = ["Khandagiri Square", "Kolathia", "Aiginia", "Alu Godam", "Kids Hospital", "Dumduma"]
FIRE_TO_SUM = [
    "Fire Station Square", "CRPF KV", "Rental Colony", "Jagannath Vihar", "Agriculture Directorate",
    "Kalinga Studio Square", "Ayurveda College", "Shyampur", "SUM Hospital",
]


def j(*segments):
    """Join corridor segments, dropping the shared stop at each joint."""
    out = []
    for seg in segments:
        for s in seg:
            if not out or out[-1] != s:
                out.append(s)
    return out


def rev(seg):
    return list(reversed(seg))


# (ref, name, colour, stops)
MOBUS_ROUTES = [
    ("10", "Airport - Biju Patnaik Park, Cuttack (via Nandankanan)", "#22B3D6", j(
        AIRPORT_TO_AG, AG_TO_JAYDEV_VIA_STADIUM, rev(KALINGA_HOSP_TO_JAYDEV), rev(DAMANA_TO_KALINGA_HOSP),
        rev(PATIA_TO_DAMANA), ["Patia Square", "CIPET", "Infocity Square"], rev(KIIT_TO_INFOCITY), NANDANKANAN_RD,
        CUTTACK_WEST)),
    ("11", "Nandan Vihar - Bhubaneswar Railway Station", "#F07C7C", j(
        ["Nandan Vihar", "Shikharchandi Vihar", "KIIT Square"], KIIT_TO_INFOCITY, INFOCITY_TO_DAMANA,
        DAMANA_TO_KALINGA_HOSP, KALINGA_HOSP_TO_ACHARYA, ["Acharya Vihar Square", "Vanivihar Square"],
        VANIVIHAR_TO_STATION)),
    ("12", "Bhubaneswar Railway Station - Nandankanan", "#9B4FB0", j(
        STATION_TO_JAYDEV_VIA_STADIUM, rev(KALINGA_HOSP_TO_JAYDEV), rev(DAMANA_TO_KALINGA_HOSP), rev(PATIA_TO_DAMANA),
        ["Patia Square", "Koel Campus", "KIIT Square"], NANDANKANAN_RD[:8])),
    ("13", "Nandan Vihar - Lingipur", "#A3202A", j(
        ["Nandan Vihar", "Shikharchandi Vihar", "KIIT Square"], KIIT_TO_INFOCITY, INFOCITY_TO_DAMANA,
        DAMANA_TO_KALINGA_HOSP, KALINGA_HOSP_TO_ACHARYA, ACHARYA_TO_AG, ["AG Square", "Raj Mahal Square"],
        RAJMAHAL_TO_RAVI, RAVI_TO_UTTARA[:8])),
    ("16", "Bhubaneswar Railway Station - Biju Patnaik Park, Cuttack (via NH)", "#A98BCB", j(
        rev(VANIVIHAR_TO_STATION), TRUNK_EAST, NH_SOUTH,
        ["Link Road", "Nisamani Talkies", "Arundoya Market", "Pala Mandap", "Badambadi Bus Stand", "Khannagar Traffic",
         "City College"], CUTTACK_EAST[6:], CUTTACK_WEST)),
    ("17", "Airport - Barabati Stadium, Cuttack (via NH)", "#62B946", j(
        AIRPORT_TO_AG, rev(ACHARYA_TO_AG), ["Acharya Vihar Square", "Vanivihar Square"], TRUNK_EAST, NH_SOUTH,
        CUTTACK_EAST, ["Judicial Academy", "Dagarpada Road", "Krushak Bazaar", "Bidanasi", "Chahata Ghata",
                       "Police Signal Traffic School", "Shifa Hospital", "Deer Park", "Baliyatra Ground",
                       "Barabati Stadium"])),
    ("18", "Baramunda ISBT - Jagatpur (via Nandankanan)", "#8B4A1F", j(
        ["Baramunda ISBT", "Baramunda", "Rajdhani College", "Fire Station Square"], rev(DIAGONAL),
        rev(KALINGA_HOSP_TO_JAYDEV), rev(DAMANA_TO_KALINGA_HOSP), rev(PATIA_TO_DAMANA),
        ["Patia Square", "Koel Campus", "KIIT Square"], NANDANKANAN_RD, rev(CUTTACK_EAST),
        ["Link Road", "Samrat Cinema", "OMP Square", "Gandarpur", "Shikharpur", "Jagatpur"])),
    ("19", "AIIMS - OMP Square, Cuttack (via NH)", "#4B3A5A", j(
        ["AIIMS", "Police Academy", "Alu Godam"], rev(FIRE_TO_ALU_GODAM), rev(DIAGONAL), TRUNK_WEST, TRUNK_EAST,
        NH_SOUTH, ["Link Road", "Samrat Cinema", "OMP Square"])),
    ("20", "Bhubaneswar Railway Station - Khordha (via Vani Vihar)", "#D63C8E", j(
        rev(VANIVIHAR_TO_STATION), rev(TRUNK_WEST), DIAGONAL, FIRE_TO_ALU_GODAM, ALU_GODAM_TO_KHORDHA)),
    ("21", "Bhubaneswar Railway Station - Khordha (via OUAT)", "#E8262A", j(
        STATION_TO_RAJMAHAL, ["Raj Mahal Square", "AG Square", "Capital Hospital", "New Airport Square", "Unit 6",
                              "OUAT Square"], rev(FIRE_TO_OUAT), FIRE_TO_ALU_GODAM, ALU_GODAM_TO_KHORDHA)),
    ("22", "Bhubaneswar Railway Station - Khordha (via Jatani)", "#7DC242", j(
        STATION_TO_RAJMAHAL, RAJMAHAL_TO_LINGARAJ_STN,
        ["Lingaraj Station", "Sundarpada Square", "Gauri Dham", "Botanda", "Chandi Bazaar", "Kantilo", "Khetrapala",
         "Biri Bandha", "Srusti Mansion", "Pradhan Sahi", "Aryan College", "Jamukoli", "Bahupada", "OEC", "XUB",
         "Niranjanpur Square", "Harirajpur Square", "Baba Somanatha Square", "Kudiary High School",
         "Nilakantheswar Square", "Sayeed Memorial Hospital", "Khordha Road Station", "Jatani PS",
         "Jatani Municipal Council", "Haribana Square", "Block Square", "IIT Road", "NISER", "Padanpur",
         "BSF Battalion Camp", "Khordha Bypass Square", "Khordha New Bus Stand"])),
    ("23", "Bhubaneswar Railway Station - SUM Hospital", "#E8742A", j(
        STATION_TO_RAJMAHAL, ["Raj Mahal Square", "AG Square"], rev(OUAT_TO_AG), rev(FIRE_TO_OUAT), FIRE_TO_SUM)),
    ("24", "Sai Temple - Kalinga Vihar", "#3AACE4", j(
        ["Sai Temple", "Megheswar Temple", "Brahmeswar Patna", "Ratnakar Bagh", "Chili Pokhari", "Raja Rani Temple",
         "Ravi Talkies Square", "Kalpana Square"], rev(RASULGARH_TO_KALPANA), rev(TRUNK_EAST), rev(TRUNK_WEST),
        DIAGONAL, ["Fire Station Square", "Rajdhani College", "Baramunda", "Khandagiri Bypass Road",
                   "Khandagiri Square", "Kolathia", "Aiginia", "Alu Godam", "Patrapada", "K9", "Kalinga Vihar Square",
                   "Kalinga Vihar K5", "Hanuman Mandir", "Kalinga Vihar"])),
    ("25", "Mancheswar - Dumduma (Ranasinghpur)", "#3CA03C", j(
        ["Mancheswar Station", "Dhirikuti Sahi", "DL Colony", "VSS Nagar Market", "VSS Nagar", "PNT Colony",
         "VSS Nagar Road", "Satsang Vihar", "Vanivihar Square"], VANIVIHAR_TO_STATION[:-1],
        ["Master Canteen", "Raj Mahal Square"], RAJMAHAL_TO_LINGARAJ_STN,
        ["Lingaraj Station", "Pokhariput", "Ganganagar Square", "Housing Board Colony", "Madhusudan Park",
         "Kalabhoomi", "ITER College", "Jagamara", "Jagannath Temple (Khandagiri)", "Khandagiri Square"],
        KHANDAGIRI_TO_DUMDUMA, ["Dumduma", "Raghunath Nagar", "Ranasinghpur"])),
    ("26", "Chakeisiani - Dumduma (Jadupur)", "#F2B65C", j(
        ["Chakeisiani", "Mancheswar Railway Station Road", "CIME College", "IDCO Tower", "SBI Chhak", "Mancheswar PS",
         "Rasulgarh Square"], rev(TRUNK_EAST), VANIVIHAR_TO_STATION[:-1], ["Master Canteen", "Raj Mahal Square",
                                                                           "AG Square", "Capital Hospital",
                                                                           "New Airport Square", "Unit 6",
                                                                           "OUAT Square"],
        ["OUAT Square", "Krushi Vihar Square", "Soubhagya Nagar", "Soubhagya Nagar Phase-2", "Baramunda Shiva Temple",
         "Dharma Vihar Road", "Mallick Complex", "Jagamara", "Jagannath Temple (Khandagiri)", "Khandagiri Square"],
        KHANDAGIRI_TO_DUMDUMA, ["Dumduma", "Dumduma Housing Board Colony", "Jadupur"])),
    ("27", "Bhubaneswar Railway Station - AIIMS", "#9A6B3F", j(
        STATION_TO_RAJMAHAL, ["Raj Mahal Square", "AG Square", "Unit 8 Colony", "OUAT Guest House", "CBI Office",
                              "Jaleswar Temple", "Delta Square", "Vivekanand Hospital", "Fire Station Square"],
        FIRE_TO_ALU_GODAM, ["Alu Godam", "Police Academy", "AIIMS"])),
    ("28", "Bhubaneswar Railway Station - Kalinga Nagar", "#3A4FA0", j(
        ["Bhubaneswar Railway Station", "Master Canteen", "AG Square", "Power House Square", "Kalyani Market",
         "Unit 8 Square", "Passport Office", "CPWD Office", "Gopabandhu Nagar", "Fire Station Square",
         "Rajdhani College", "Baramunda", "Khandagiri Bypass Road", "Binayaka Enclave", "Satya Sai Enclave",
         "AMRI Hospital", "Jaydev Vatika", "Jaydev Vatika Square", "Khandagiribari", "Naka Gate", "CET College",
         "Valia Square", "Ghatikia", "K7 Kalyan Mandap", "Kalinga Nagar", "Paikarapur (Kalinga Nagar)",
         "Paikarapur Housing Colony", "Trident Galaxy"])),
    ("29", "Kalinga Vihar (K9B) - Sai Temple", "#8F9BD6", j(
        ["K9 B", "K9 Lane 4", "Kalinga Vihar Square", "K9", "Patrapada", "Alu Godam"], rev(FIRE_TO_ALU_GODAM),
        rev(DIAGONAL), TRUNK_WEST, TRUNK_EAST, RASULGARH_TO_KALPANA[:-1],
        ["Sabarashi Lane", "RI Office", "BJEM School", "Biswanath Nagar", "Badagada Haat", "Badagada High School",
         "Badagada PS", "Panchu Pandav Caves", "BDA Park", "Badagada Brit Colony", "Sai Temple"])),
    ("29E", "Kalinga Vihar (K9B) - SBI Colony, Kesora", "#8F9BD6", None),  # filled below
    ("30", "Bhubaneswar Railway Station - Chatabar (via SUM Hospital)", "#1E4D7A", j(
        ["Bhubaneswar Railway Station", "Master Canteen", "AG Square"], rev(OUAT_TO_AG), rev(FIRE_TO_OUAT),
        FIRE_TO_SUM[:-1], ["Shyampur", "Nuagaon Square", "Malipada", "RI Paikarapur", "Gothapatna Square",
                           "IIIT Square", "Paikarapur", "ROTI", "Kateni", "Adurta Sishu Sadan", "Giringaput",
                           "OPTCL Grid Sub Station", "Community Health Centre", "Mendhasal",
                           "Biju Patnaik Open Air Ashram", "Chatabar"])),
    ("31", "Bhubaneswar Railway Station - Hi-Tech Hospital", "#E6C800", [
        "Bhubaneswar Railway Station", "Old Station Bazaar", "Laxmi Sagar Square", "Laxmi Sagar", "Laxmi Sagar PS",
        "Jail Square", "Ganesh Mandap", "Santi Nagar", "Shibani Enclave", "Bhagabat Sandhan", "GGP Canal Road",
        "GGP Colony", "Srusti Villa", "Pandara Square", "Pandara Market", "Hi-Tech Hospital"]),
    ("32", "Baramunda ISBT - Lingaraj Temple", "#4A2F82", j(
        ["Baramunda ISBT", "Baramunda", "Rajdhani College", "Fire Station Square"], rev(DIAGONAL), TRUNK_WEST,
        VANIVIHAR_TO_STATION[:-1], ["Master Canteen", "Raj Mahal Square"], RAJMAHAL_TO_RAVI,
        ["Ravi Talkies Square", "Lingaraj Temple"])),
    ("33", "Bhubaneswar Railway Station - Pipili", "#A6A53A", j(
        STATION_TO_RAJMAHAL, RAJMAHAL_TO_RAVI, RAVI_TO_UTTARA, UTTARA_TO_PIPILI)),
    ("34", "Bhubaneswar Railway Station - Balakati (Sai Hospital)", "#55554D", j(
        STATION_TO_RAJMAHAL, RAJMAHAL_TO_RAVI, RAVI_TO_UTTARA,
        ["Uttara Square", "Saradeipur", "Balakati Govt School", "Balakati", "Balakati Post Office", "Dulladei Temple",
         "Sai Hospital"])),
    ("50", "Bhubaneswar Railway Station - Puri Bus Stand", "#3B2049", j(
        STATION_TO_RAJMAHAL, RAJMAHAL_TO_RAVI, RAVI_TO_UTTARA, UTTARA_TO_PIPILI, PIPILI_TO_PURI)),
    ("51", "Baramunda ISBT - Puri Bus Stand", "#5CC4CA", j(
        ["Baramunda ISBT", "Baramunda", "Rajdhani College", "Fire Station Square"], rev(DIAGONAL), TRUNK_WEST,
        TRUNK_EAST, RASULGARH_TO_KALPANA, RAJMAHAL_TO_RAVI[1:], RAVI_TO_UTTARA, UTTARA_TO_PIPILI, PIPILI_TO_PURI)),
    ("70", "Bhubaneswar Railway Station - Konark", "#8C6A2A", j(
        STATION_TO_RAJMAHAL, RAJMAHAL_TO_RAVI, RAVI_TO_UTTARA, UTTARA_TO_PIPILI,
        ["Pipili Nimapada Square", "Nimapada Bus Stand", "Gop Market", "Gop PS", "Begunia", "Sareda", "Junei",
         "Madipur Chhak", "Konark PS", "Sun Temple Konark", "Konark"])),
]

# 29E shares route 29 up to Sai Temple, then continues to Kesora.
_r29 = next(r for r in MOBUS_ROUTES if r[0] == "29")[3]
MOBUS_ROUTES = [
    (ref, name, color, stops if ref != "29E" else _r29 + ["SR Valley", "Mangraj Point", "Jena Market", "SBI Colony (Kesora)"])
    for ref, name, color, stops in MOBUS_ROUTES
]
