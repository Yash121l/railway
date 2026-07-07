import type { Train } from "./types";

/**
 * Eight real Indian Railways services, schedules researched from public
 * timetables (etrain.info / indiarailinfo / Wikipedia) and trimmed to major
 * commercial halts. Times are minute-offsets from origin departure (IST).
 */
export const TRAINS: Train[] = [
  {
    "number": "12951",
    "name": "Mumbai Rajdhani Express",
    "category": "rajdhani",
    "departureTime": "17:00",
    "days": [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
    ],
    "distanceKm": 1384,
    "stops": [
      {
        "name": "Mumbai Central",
        "code": "MMCT",
        "lat": 18.9691,
        "lng": 72.8194,
        "arrMin": 0,
        "depMin": 0,
        "platform": "2"
      },
      {
        "name": "Borivali",
        "code": "BVI",
        "lat": 19.2307,
        "lng": 72.8567,
        "arrMin": 20,
        "depMin": 22,
        "platform": "6"
      },
      {
        "name": "Surat",
        "code": "ST",
        "lat": 21.2049,
        "lng": 72.841,
        "arrMin": 163,
        "depMin": 168,
        "platform": "1"
      },
      {
        "name": "Vadodara Junction",
        "code": "BRC",
        "lat": 22.3072,
        "lng": 73.1812,
        "arrMin": 246,
        "depMin": 256,
        "platform": "2"
      },
      {
        "name": "Ratlam Junction",
        "code": "RTM",
        "lat": 23.3315,
        "lng": 75.0367,
        "arrMin": 445,
        "depMin": 448,
        "platform": "5"
      },
      {
        "name": "Nagda Junction",
        "code": "NAD",
        "lat": 23.4455,
        "lng": 75.417,
        "arrMin": 488,
        "depMin": 490,
        "platform": "1"
      },
      {
        "name": "Kota Junction",
        "code": "KOTA",
        "lat": 25.178,
        "lng": 75.8577,
        "arrMin": 615,
        "depMin": 620,
        "platform": "1"
      },
      {
        "name": "New Delhi",
        "code": "NDLS",
        "lat": 28.6431,
        "lng": 77.2197,
        "arrMin": 932,
        "depMin": 932,
        "platform": "3"
      }
    ]
  },
  {
    "number": "12301",
    "name": "Howrah - New Delhi Rajdhani Express (Via Gaya)",
    "category": "rajdhani",
    "departureTime": "16:50",
    "days": [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat"
    ],
    "distanceKm": 1449,
    "stops": [
      {
        "name": "Howrah Jn",
        "code": "HWH",
        "lat": 22.5839,
        "lng": 88.3434,
        "arrMin": 0,
        "depMin": 0,
        "platform": "9"
      },
      {
        "name": "Asansol Jn",
        "code": "ASN",
        "lat": 23.6889,
        "lng": 86.9661,
        "arrMin": 117,
        "depMin": 119,
        "platform": "4"
      },
      {
        "name": "Dhanbad Jn",
        "code": "DHN",
        "lat": 23.7957,
        "lng": 86.4304,
        "arrMin": 185,
        "depMin": 190,
        "platform": "3"
      },
      {
        "name": "Parasnath",
        "code": "PNME",
        "lat": 23.9995,
        "lng": 86.1616,
        "arrMin": 220,
        "depMin": 222,
        "platform": "3"
      },
      {
        "name": "Gaya Jn",
        "code": "GAYA",
        "lat": 24.8035,
        "lng": 85.0099,
        "arrMin": 342,
        "depMin": 345,
        "platform": "1"
      },
      {
        "name": "Pt. Deen Dayal Upadhyaya Jn",
        "code": "DDU",
        "lat": 25.2815,
        "lng": 83.1198,
        "arrMin": 470,
        "depMin": 480,
        "platform": "7"
      },
      {
        "name": "Prayagraj Jn",
        "code": "PRYJ",
        "lat": 25.4442,
        "lng": 81.8252,
        "arrMin": 593,
        "depMin": 595,
        "platform": "1"
      },
      {
        "name": "Kanpur Central",
        "code": "CNB",
        "lat": 26.4536,
        "lng": 80.3508,
        "arrMin": 720,
        "depMin": 725,
        "platform": "1"
      },
      {
        "name": "New Delhi",
        "code": "NDLS",
        "lat": 28.6428,
        "lng": 77.2197,
        "arrMin": 1035,
        "depMin": 1035,
        "platform": "16"
      }
    ]
  },
  {
    "number": "22436",
    "name": "New Delhi - Varanasi Vande Bharat Express",
    "category": "vande-bharat",
    "departureTime": "06:00",
    "days": [
      "Mon",
      "Tue",
      "Wed",
      "Fri",
      "Sat",
      "Sun"
    ],
    "distanceKm": 771,
    "stops": [
      {
        "name": "New Delhi",
        "code": "NDLS",
        "lat": 28.643,
        "lng": 77.2195,
        "arrMin": 0,
        "depMin": 0
      },
      {
        "name": "Kanpur Central",
        "code": "CNB",
        "lat": 26.4536,
        "lng": 80.3508,
        "arrMin": 248,
        "depMin": 250,
        "platform": "1"
      },
      {
        "name": "Prayagraj Junction",
        "code": "PRYJ",
        "lat": 25.445,
        "lng": 81.825,
        "arrMin": 368,
        "depMin": 370,
        "platform": "1"
      },
      {
        "name": "Varanasi Junction",
        "code": "BSB",
        "lat": 25.3207,
        "lng": 82.9863,
        "arrMin": 480,
        "depMin": 480
      }
    ]
  },
  {
    "number": "20901",
    "name": "Mumbai Central - Gandhinagar Capital Vande Bharat Express",
    "category": "vande-bharat",
    "departureTime": "06:00",
    "days": [
      "Mon",
      "Tue",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
    ],
    "distanceKm": 521,
    "stops": [
      {
        "name": "Mumbai Central",
        "code": "MMCT",
        "lat": 18.9691,
        "lng": 72.8193,
        "arrMin": 0,
        "depMin": 0
      },
      {
        "name": "Borivali",
        "code": "BVI",
        "lat": 19.229,
        "lng": 72.857,
        "arrMin": 23,
        "depMin": 25
      },
      {
        "name": "Vapi",
        "code": "VAPI",
        "lat": 20.372,
        "lng": 72.917,
        "arrMin": 113,
        "depMin": 115
      },
      {
        "name": "Valsad",
        "code": "BL",
        "lat": 20.607,
        "lng": 72.934,
        "arrMin": 138,
        "depMin": 140
      },
      {
        "name": "Navsari",
        "code": "NVS",
        "lat": 20.951,
        "lng": 72.939,
        "arrMin": 163,
        "depMin": 165
      },
      {
        "name": "Surat",
        "code": "ST",
        "lat": 21.205,
        "lng": 72.841,
        "arrMin": 185,
        "depMin": 188
      },
      {
        "name": "Vadodara Junction",
        "code": "BRC",
        "lat": 22.31,
        "lng": 73.181,
        "arrMin": 263,
        "depMin": 266
      },
      {
        "name": "Anand Junction",
        "code": "ANND",
        "lat": 22.557,
        "lng": 72.955,
        "arrMin": 288,
        "depMin": 290
      },
      {
        "name": "Ahmedabad Junction",
        "code": "ADI",
        "lat": 23.026,
        "lng": 72.601,
        "arrMin": 335,
        "depMin": 340
      },
      {
        "name": "Gandhinagar Capital",
        "code": "GNC",
        "lat": 23.222,
        "lng": 72.683,
        "arrMin": 390,
        "depMin": 390
      }
    ]
  },
  {
    "number": "12009",
    "name": "Mumbai Central - Ahmedabad Shatabdi Express",
    "category": "shatabdi",
    "departureTime": "06:20",
    "days": [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat"
    ],
    "distanceKm": 491,
    "stops": [
      {
        "name": "Mumbai Central",
        "code": "MMCT",
        "lat": 18.9691,
        "lng": 72.8193,
        "arrMin": 0,
        "depMin": 0,
        "platform": "1"
      },
      {
        "name": "Borivali",
        "code": "BVI",
        "lat": 19.2296,
        "lng": 72.8567,
        "arrMin": 23,
        "depMin": 25,
        "platform": "6"
      },
      {
        "name": "Vapi",
        "code": "VAPI",
        "lat": 20.3719,
        "lng": 72.9107,
        "arrMin": 105,
        "depMin": 107,
        "platform": "1"
      },
      {
        "name": "Surat",
        "code": "ST",
        "lat": 21.2049,
        "lng": 72.8411,
        "arrMin": 181,
        "depMin": 184,
        "platform": "1"
      },
      {
        "name": "Bharuch Jn",
        "code": "BH",
        "lat": 21.7051,
        "lng": 72.9959,
        "arrMin": 222,
        "depMin": 224,
        "platform": "3"
      },
      {
        "name": "Vadodara Jn",
        "code": "BRC",
        "lat": 22.31,
        "lng": 73.181,
        "arrMin": 274,
        "depMin": 279,
        "platform": "2"
      },
      {
        "name": "Anand Jn",
        "code": "ANND",
        "lat": 22.5586,
        "lng": 72.9622,
        "arrMin": 310,
        "depMin": 312,
        "platform": "3"
      },
      {
        "name": "Nadiad Jn",
        "code": "ND",
        "lat": 22.6939,
        "lng": 72.8618,
        "arrMin": 326,
        "depMin": 328,
        "platform": "3"
      },
      {
        "name": "Ahmedabad Jn",
        "code": "ADI",
        "lat": 23.0258,
        "lng": 72.6011,
        "arrMin": 380,
        "depMin": 380,
        "platform": "1"
      }
    ]
  },
  {
    "number": "12259",
    "name": "Sealdah - New Delhi AC Duronto Express",
    "category": "duronto",
    "departureTime": "17:00",
    "days": [
      "Sun",
      "Mon",
      "Wed",
      "Thu"
    ],
    "distanceKm": 1455,
    "stops": [
      {
        "name": "Sealdah",
        "code": "SDAH",
        "lat": 22.5678,
        "lng": 88.37,
        "arrMin": 0,
        "depMin": 0,
        "platform": "13"
      },
      {
        "name": "Asansol Jn",
        "code": "ASN",
        "lat": 23.6839,
        "lng": 86.9873,
        "arrMin": 157,
        "depMin": 159
      },
      {
        "name": "Dhanbad Jn",
        "code": "DHN",
        "lat": 23.7957,
        "lng": 86.4304,
        "arrMin": 210,
        "depMin": 215,
        "platform": "3"
      },
      {
        "name": "Koderma Jn",
        "code": "KQR",
        "lat": 24.4675,
        "lng": 85.594,
        "arrMin": 285,
        "depMin": 287
      },
      {
        "name": "Gaya Jn",
        "code": "GAYA",
        "lat": 24.7955,
        "lng": 84.9994,
        "arrMin": 350,
        "depMin": 352
      },
      {
        "name": "Pt. Deen Dayal Upadhyaya Jn",
        "code": "DDU",
        "lat": 25.2815,
        "lng": 83.1198,
        "arrMin": 500,
        "depMin": 507,
        "platform": "4"
      },
      {
        "name": "Prayagraj Jn",
        "code": "PRYJ",
        "lat": 25.4435,
        "lng": 81.825,
        "arrMin": 610,
        "depMin": 612
      },
      {
        "name": "Kanpur Central",
        "code": "CNB",
        "lat": 26.4545,
        "lng": 80.3517,
        "arrMin": 745,
        "depMin": 750,
        "platform": "2"
      },
      {
        "name": "New Delhi",
        "code": "NDLS",
        "lat": 28.6428,
        "lng": 77.2197,
        "arrMin": 1080,
        "depMin": 1080,
        "platform": "9"
      }
    ]
  },
  {
    "number": "12841",
    "name": "Coromandel Express",
    "category": "superfast",
    "departureTime": "15:20",
    "days": [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
    ],
    "distanceKm": 1659,
    "stops": [
      {
        "name": "Shalimar",
        "code": "SHM",
        "lat": 22.5548,
        "lng": 88.3084,
        "arrMin": 0,
        "depMin": 0
      },
      {
        "name": "Kharagpur Junction",
        "code": "KGP",
        "lat": 22.3396,
        "lng": 87.3252,
        "arrMin": 95,
        "depMin": 100,
        "platform": "3"
      },
      {
        "name": "Balasore",
        "code": "BLS",
        "lat": 21.4942,
        "lng": 86.9317,
        "arrMin": 175,
        "depMin": 180
      },
      {
        "name": "Bhadrak",
        "code": "BHC",
        "lat": 21.0692,
        "lng": 86.4926,
        "arrMin": 238,
        "depMin": 240
      },
      {
        "name": "Cuttack",
        "code": "CTC",
        "lat": 20.4686,
        "lng": 85.8792,
        "arrMin": 348,
        "depMin": 353
      },
      {
        "name": "Bhubaneswar",
        "code": "BBS",
        "lat": 20.2665,
        "lng": 85.8438,
        "arrMin": 390,
        "depMin": 395,
        "platform": "1"
      },
      {
        "name": "Brahmapur",
        "code": "BAM",
        "lat": 19.3115,
        "lng": 84.7941,
        "arrMin": 523,
        "depMin": 525
      },
      {
        "name": "Visakhapatnam",
        "code": "VSKP",
        "lat": 17.6868,
        "lng": 83.2185,
        "arrMin": 780,
        "depMin": 800,
        "platform": "1"
      },
      {
        "name": "Rajahmundry",
        "code": "RJY",
        "lat": 17.0005,
        "lng": 81.7768,
        "arrMin": 953,
        "depMin": 955
      },
      {
        "name": "Vijayawada Junction",
        "code": "BZA",
        "lat": 16.5178,
        "lng": 80.6197,
        "arrMin": 1130,
        "depMin": 1140
      },
      {
        "name": "MGR Chennai Central",
        "code": "MAS",
        "lat": 13.0823,
        "lng": 80.2755,
        "arrMin": 1540,
        "depMin": 1540
      }
    ]
  },
  {
    "number": "12627",
    "name": "Karnataka Express",
    "category": "superfast",
    "departureTime": "19:20",
    "days": [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
    ],
    "distanceKm": 2395,
    "stops": [
      {
        "name": "KSR Bengaluru City Junction",
        "code": "SBC",
        "lat": 12.9784,
        "lng": 77.57,
        "arrMin": 0,
        "depMin": 0
      },
      {
        "name": "Guntakal Junction",
        "code": "GTL",
        "lat": 15.171,
        "lng": 77.373,
        "arrMin": 305,
        "depMin": 310
      },
      {
        "name": "Kalaburagi Junction",
        "code": "KLBG",
        "lat": 17.329,
        "lng": 76.834,
        "arrMin": 597,
        "depMin": 600
      },
      {
        "name": "Solapur Junction",
        "code": "SUR",
        "lat": 17.659,
        "lng": 75.906,
        "arrMin": 710,
        "depMin": 715
      },
      {
        "name": "Daund Junction",
        "code": "DD",
        "lat": 18.465,
        "lng": 74.58,
        "arrMin": 880,
        "depMin": 885
      },
      {
        "name": "Manmad Junction",
        "code": "MMR",
        "lat": 20.253,
        "lng": 74.439,
        "arrMin": 1170,
        "depMin": 1175
      },
      {
        "name": "Bhusaval Junction",
        "code": "BSL",
        "lat": 21.045,
        "lng": 75.785,
        "arrMin": 1310,
        "depMin": 1315
      },
      {
        "name": "Itarsi Junction",
        "code": "ET",
        "lat": 22.615,
        "lng": 77.762,
        "arrMin": 1560,
        "depMin": 1565
      },
      {
        "name": "Bhopal Junction",
        "code": "BPL",
        "lat": 23.259,
        "lng": 77.413,
        "arrMin": 1660,
        "depMin": 1665
      },
      {
        "name": "Virangana Lakshmibai Jhansi Junction",
        "code": "VGLJ",
        "lat": 25.448,
        "lng": 78.578,
        "arrMin": 1890,
        "depMin": 1898
      },
      {
        "name": "Gwalior Junction",
        "code": "GWL",
        "lat": 26.216,
        "lng": 78.181,
        "arrMin": 1965,
        "depMin": 1967
      },
      {
        "name": "Agra Cantt",
        "code": "AGC",
        "lat": 27.157,
        "lng": 77.99,
        "arrMin": 2055,
        "depMin": 2060
      },
      {
        "name": "Mathura Junction",
        "code": "MTJ",
        "lat": 27.482,
        "lng": 77.685,
        "arrMin": 2100,
        "depMin": 2105
      },
      {
        "name": "New Delhi",
        "code": "NDLS",
        "lat": 28.6427,
        "lng": 77.219,
        "arrMin": 2260,
        "depMin": 2260
      }
    ]
  }
];
