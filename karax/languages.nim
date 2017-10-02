## Karax -- Single page applications for Nim.

type
  Language* {.pure.} = enum ## A pure enum that contains most (all?)
                            ## known human languages in current use.
    afZA ## "South Africa - Afrikaans"
    amET ## "Ethiopia - Amharic"
    arAE ## "U.A.E. - Arabic"
    arBH ## "Bahrain - Arabic"
    arDZ ## "Algeria - Arabic"
    arEG ## "Egypt - Arabic"
    arIQ ## "Iraq - Arabic"
    arJO ## "Jordan - Arabic"
    arKW ## "Kuwait - Arabic"
    arLB ## "Lebanon - Arabic"
    arLY ## "Libya - Arabic"
    arMA ## "Morocco - Arabic"
    arOM ## "Oman - Arabic"
    arQA ## "Qatar - Arabic"
    arSA ## "Saudi Arabia - Arabic"
    arSY ## "Syria - Arabic"
    arTN ## "Tunisia - Arabic"
    arYE ## "Yemen - Arabic"
    arnCL ## "Chile - Mapudungun"
    asIN ## "India - Assamese"
    azAZ ## "Azerbaijan - Azeri (Cyrillic)"
    baRU ## "Russia - Bashkir"
    beBY ## "Belarus - Belarusian"
    bgBG ## "Bulgaria - Bulgarian"
    bnBD ## "Bangladesh - Bengali"
    bnIN ## "India - Bengali"
    boCN ## "People's Republic of China - Tibetan"
    brFR ## "France - Breton"
    bsBA ## "Bosnia and Herzegovina - Bosnian (Cyrillic)"
    caES ## "Spain - Catalan"
    coFR ## "France - Corsican"
    csCZ ## "Czech Republic - Czech"
    cyGB ## "United Kingdom - Welsh"
    daDK ## "Denmark - Danish"
    deAT ## "Austria - German"
    deCH ## "Switzerland - German"
    deDE ## "Germany - German"
    deLI ## "Liechtenstein - German"
    deLU ## "Luxembourg - German"
    dsbDE ## "Germany - Lower Sorbian"
    dvMV ## "Maldives - Divehi"
    elGR ## "Greece - Greek"
    en029 ## "Caribbean - English"
    enAU ## "Australia - English"
    enBZ ## "Belize - English"
    enCA ## "Canada - English"
    enGB ## "United Kingdom - English"
    enIE ## "Ireland - English"
    enIN ## "India - English"
    enJM ## "Jamaica - English"
    enMY ## "Malaysia - English"
    enNZ ## "New Zealand - English"
    enPH ## "Republic of the Philippines - English"
    enSG ## "Singapore - English"
    enTT ## "Trinidad and Tobago - English"
    enUS ## "United States - English"
    enZA ## "South Africa - English"
    enZW ## "Zimbabwe - English"
    esAR ## "Argentina - Spanish"
    esBO ## "Bolivia - Spanish"
    esCL ## "Chile - Spanish"
    esCO ## "Colombia - Spanish"
    esCR ## "Costa Rica - Spanish"
    esDO ## "Dominican Republic - Spanish"
    esEC ## "Ecuador - Spanish"
    esES ## "Spain - Spanish"
    esGT ## "Guatemala - Spanish"
    esHN ## "Honduras - Spanish"
    esMX ## "Mexico - Spanish"
    esNI ## "Nicaragua - Spanish"
    esPA ## "Panama - Spanish"
    esPE ## "Peru - Spanish"
    esPR ## "Puerto Rico - Spanish"
    esPY ## "Paraguay - Spanish"
    esSV ## "El Salvador - Spanish"
    esUS ## "United States - Spanish"
    esUY ## "Uruguay - Spanish"
    esVE ## "Bolivarian Republic of Venezuela - Spanish"
    etEE ## "Estonia - Estonian"
    euES ## "Spain - Basque"
    faIR ## "Iran - Persian"
    fiFI ## "Finland - Finnish"
    filPH ## "Philippines - Filipino"
    foFO ## "Faroe Islands - Faroese"
    frBE ## "Belgium - French"
    frCA ## "Canada - French"
    frCH ## "Switzerland - French"
    frFR ## "France - French"
    frLU ## "Luxembourg - French"
    frMC ## "Principality of Monaco - French"
    fyNL ## "Netherlands - Frisian"
    gaIE ## "Ireland - Irish"
    gdGB ## "United Kingdom - Scottish Gaelic"
    glES ## "Spain - Galician"
    gswFR ## "France - Alsatian"
    guIN ## "India - Gujarati"
    haNG ## "Nigeria - Hausa (Latin)"
    heIL ## "Israel - Hebrew"
    hiIN ## "India - Hindi"
    hrBA ## "Bosnia and Herzegovina - Croatian"
    hrHR ## "Croatia - Croatian"
    hsbDE ## "Germany - Upper Sorbian"
    huHU ## "Hungary - Hungarian"
    hyAM ## "Armenia - Armenian"
    idID ## "Indonesia - Indonesian"
    igNG ## "Nigeria - Igbo"
    iiCN ## "People's Republic of China - Yi"
    isIS ## "Iceland - Icelandic"
    itCH ## "Switzerland - Italian"
    itIT ## "Italy - Italian"
    iuCA ## "Canada - Inuktitut (Latin)"
    jaJP ## "Japan - Japanese"
    kaGE ## "Georgia - Georgian"
    kkKZ ## "Kazakhstan - Kazakh"
    klGL ## "Greenland - Greenlandic"
    kmKH ## "Cambodia - Khmer"
    knIN ## "India - Kannada"
    koKR ## "Korea - Korean"
    kokIN ## "India - Konkani"
    kyKG ## "Kyrgyzstan - Kyrgyz"
    lbLU ## "Luxembourg - Luxembourgish"
    loLA ## "Lao P.D.R. - Lao"
    ltLT ## "Lithuania - Lithuanian"
    lvLV ## "Latvia - Latvian"
    miNZ ## "New Zealand - Maori"
    mkMK ## "Macedonia (FYROM) - Macedonian (FYROM)"
    mlIN ## "India - Malayalam"
    mnCN ## "People's Republic of China - Mongolian (Traditional Mongolian)"
    mnMN ## "Mongolia - Mongolian (Cyrillic)"
    mohCA ## "Canada - Mohawk"
    mrIN ## "India - Marathi"
    msBN ## "Brunei Darussalam - Malay"
    msMY ## "Malaysia - Malay"
    mtMT ## "Malta - Maltese"
    nbNO ## "Norway - Norwegian (Bokmal)"
    neNP ## "Nepal - Nepali"
    nlBE ## "Belgium - Dutch"
    nlNL ## "Netherlands - Dutch"
    nnNO ## "Norway - Norwegian (Nynorsk)"
    nsoZA ## "South Africa - Sesotho sa Leboa"
    ocFR ## "France - Occitan"
    orIN ## "India - Oriya"
    paIN ## "India - Punjabi"
    plPL ## "Poland - Polish"
    prsAF ## "Afghanistan - Dari"
    psAF ## "Afghanistan - Pashto"
    ptBR ## "Brazil - Portuguese"
    ptPT ## "Portugal - Portuguese"
    qutGT ## "Guatemala - K'iche"
    quzBO ## "Bolivia - Quechua"
    quzEC ## "Ecuador - Quechua"
    quzPE ## "Peru - Quechua"
    rmCH ## "Switzerland - Romansh"
    roRO ## "Romania - Romanian"
    ruRU ## "Russia - Russian"
    rwRW ## "Rwanda - Kinyarwanda"
    saIN ## "India - Sanskrit"
    sahRU ## "Russia - Yakut"
    seFI ## "Finland - Sami (Northern)"
    seNO ## "Norway - Sami (Northern)"
    seSE ## "Sweden - Sami (Northern)"
    siLK ## "Sri Lanka - Sinhala"
    skSK ## "Slovakia - Slovak"
    slSI ## "Slovenia - Slovenian"
    smaNO ## "Norway - Sami (Southern)"
    smaSE ## "Sweden - Sami (Southern)"
    smjNO ## "Norway - Sami (Lule)"
    smjSE ## "Sweden - Sami (Lule)"
    smnFI ## "Finland - Sami (Inari)"
    smsFI ## "Finland - Sami (Skolt)"
    sqAL ## "Albania - Albanian"
    srBA ## "Bosnia and Herzegovina - Serbian (Cyrillic)"
    srCS ## "Serbia and Montenegro (Former) - Serbian (Cyrillic)"
    srME ## "Montenegro - Serbian (Cyrillic)"
    srRS ## "Serbia - Serbian (Cyrillic)"
    svFI ## "Finland - Swedish"
    svSE ## "Sweden - Swedish"
    swKE ## "Kenya - Kiswahili"
    syrSY ## "Syria - Syriac"
    taIN ## "India - Tamil"
    teIN ## "India - Telugu"
    tgTJ ## "Tajikistan - Tajik (Cyrillic)"
    thTH ## "Thailand - Thai"
    tkTM ## "Turkmenistan - Turkmen"
    tnZA ## "South Africa - Setswana"
    trTR ## "Turkey - Turkish"
    ttRU ## "Russia - Tatar"
    tzmDZ ## "Algeria - Tamazight (Latin)"
    ugCN ## "People's Republic of China - Uyghur"
    ukUA ## "Ukraine - Ukrainian"
    urPK ## "Islamic Republic of Pakistan - Urdu"
    uzUZ ## "Uzbekistan - Uzbek (Cyrillic)"
    viVN ## "Vietnam - Vietnamese"
    woSN ## "Senegal - Wolof"
    xhZA ## "South Africa - isiXhosa"
    yoNG ## "Nigeria - Yoruba"
    zhCN ## "People's Republic of China - Chinese (Simplified) Legacy"
    zhHK ## "Hong Kong S.A.R. - Chinese (Traditional) Legacy"
    zhMO ## "Macao S.A.R. - Chinese (Traditional) Legacy"
    zhSG ## "Singapore - Chinese (Simplified) Legacy"
    zhTW ## "Taiwan - Chinese (Traditional) Legacy"
    zuZA ## "South Africa - isiZulu"

const
  languageToName*: array[Language, cstring] = [
    Language.afZA: cstring"South Africa - Afrikaans",
    Language.amET: cstring"Ethiopia - Amharic",
    Language.arAE: cstring"U.A.E. - Arabic",
    Language.arBH: cstring"Bahrain - Arabic",
    Language.arDZ: cstring"Algeria - Arabic",
    Language.arEG: cstring"Egypt - Arabic",
    Language.arIQ: cstring"Iraq - Arabic",
    Language.arJO: cstring"Jordan - Arabic",
    Language.arKW: cstring"Kuwait - Arabic",
    Language.arLB: cstring"Lebanon - Arabic",
    Language.arLY: cstring"Libya - Arabic",
    Language.arMA: cstring"Morocco - Arabic",
    Language.arOM: cstring"Oman - Arabic",
    Language.arQA: cstring"Qatar - Arabic",
    Language.arSA: cstring"Saudi Arabia - Arabic",
    Language.arSY: cstring"Syria - Arabic",
    Language.arTN: cstring"Tunisia - Arabic",
    Language.arYE: cstring"Yemen - Arabic",
    Language.arnCL: cstring"Chile - Mapudungun",
    Language.asIN: cstring"India - Assamese",
    Language.azAZ: cstring"Azerbaijan - Azeri (Cyrillic)",
    Language.baRU: cstring"Russia - Bashkir",
    Language.beBY: cstring"Belarus - Belarusian",
    Language.bgBG: cstring"Bulgaria - Bulgarian",
    Language.bnBD: cstring"Bangladesh - Bengali",
    Language.bnIN: cstring"India - Bengali",
    Language.boCN: cstring"People's Republic of China - Tibetan",
    Language.brFR: cstring"France - Breton",
    Language.bsBA: cstring"Bosnia and Herzegovina - Bosnian (Cyrillic)",
    Language.caES: cstring"Spain - Catalan",
    Language.coFR: cstring"France - Corsican",
    Language.csCZ: cstring"Czech Republic - Czech",
    Language.cyGB: cstring"United Kingdom - Welsh",
    Language.daDK: cstring"Denmark - Danish",
    Language.deAT: cstring"Austria - German",
    Language.deCH: cstring"Switzerland - German",
    Language.deDE: cstring"Germany - German",
    Language.deLI: cstring"Liechtenstein - German",
    Language.deLU: cstring"Luxembourg - German",
    Language.dsbDE: cstring"Germany - Lower Sorbian",
    Language.dvMV: cstring"Maldives - Divehi",
    Language.elGR: cstring"Greece - Greek",
    Language.en029: cstring"Caribbean - English",
    Language.enAU: cstring"Australia - English",
    Language.enBZ: cstring"Belize - English",
    Language.enCA: cstring"Canada - English",
    Language.enGB: cstring"United Kingdom - English",
    Language.enIE: cstring"Ireland - English",
    Language.enIN: cstring"India - English",
    Language.enJM: cstring"Jamaica - English",
    Language.enMY: cstring"Malaysia - English",
    Language.enNZ: cstring"New Zealand - English",
    Language.enPH: cstring"Republic of the Philippines - English",
    Language.enSG: cstring"Singapore - English",
    Language.enTT: cstring"Trinidad and Tobago - English",
    Language.enUS: cstring"United States - English",
    Language.enZA: cstring"South Africa - English",
    Language.enZW: cstring"Zimbabwe - English",
    Language.esAR: cstring"Argentina - Spanish",
    Language.esBO: cstring"Bolivia - Spanish",
    Language.esCL: cstring"Chile - Spanish",
    Language.esCO: cstring"Colombia - Spanish",
    Language.esCR: cstring"Costa Rica - Spanish",
    Language.esDO: cstring"Dominican Republic - Spanish",
    Language.esEC: cstring"Ecuador - Spanish",
    Language.esES: cstring"Spain - Spanish",
    Language.esGT: cstring"Guatemala - Spanish",
    Language.esHN: cstring"Honduras - Spanish",
    Language.esMX: cstring"Mexico - Spanish",
    Language.esNI: cstring"Nicaragua - Spanish",
    Language.esPA: cstring"Panama - Spanish",
    Language.esPE: cstring"Peru - Spanish",
    Language.esPR: cstring"Puerto Rico - Spanish",
    Language.esPY: cstring"Paraguay - Spanish",
    Language.esSV: cstring"El Salvador - Spanish",
    Language.esUS: cstring"United States - Spanish",
    Language.esUY: cstring"Uruguay - Spanish",
    Language.esVE: cstring"Bolivarian Republic of Venezuela - Spanish",
    Language.etEE: cstring"Estonia - Estonian",
    Language.euES: cstring"Spain - Basque",
    Language.faIR: cstring"Iran - Persian",
    Language.fiFI: cstring"Finland - Finnish",
    Language.filPH: cstring"Philippines - Filipino",
    Language.foFO: cstring"Faroe Islands - Faroese",
    Language.frBE: cstring"Belgium - French",
    Language.frCA: cstring"Canada - French",
    Language.frCH: cstring"Switzerland - French",
    Language.frFR: cstring"France - French",
    Language.frLU: cstring"Luxembourg - French",
    Language.frMC: cstring"Principality of Monaco - French",
    Language.fyNL: cstring"Netherlands - Frisian",
    Language.gaIE: cstring"Ireland - Irish",
    Language.gdGB: cstring"United Kingdom - Scottish Gaelic",
    Language.glES: cstring"Spain - Galician",
    Language.gswFR: cstring"France - Alsatian",
    Language.guIN: cstring"India - Gujarati",
    Language.haNG: cstring"Nigeria - Hausa (Latin)",
    Language.heIL: cstring"Israel - Hebrew",
    Language.hiIN: cstring"India - Hindi",
    Language.hrBA: cstring"Bosnia and Herzegovina - Croatian",
    Language.hrHR: cstring"Croatia - Croatian",
    Language.hsbDE: cstring"Germany - Upper Sorbian",
    Language.huHU: cstring"Hungary - Hungarian",
    Language.hyAM: cstring"Armenia - Armenian",
    Language.idID: cstring"Indonesia - Indonesian",
    Language.igNG: cstring"Nigeria - Igbo",
    Language.iiCN: cstring"People's Republic of China - Yi",
    Language.isIS: cstring"Iceland - Icelandic",
    Language.itCH: cstring"Switzerland - Italian",
    Language.itIT: cstring"Italy - Italian",
    Language.iuCA: cstring"Canada - Inuktitut (Latin)",
    Language.jaJP: cstring"Japan - Japanese",
    Language.kaGE: cstring"Georgia - Georgian",
    Language.kkKZ: cstring"Kazakhstan - Kazakh",
    Language.klGL: cstring"Greenland - Greenlandic",
    Language.kmKH: cstring"Cambodia - Khmer",
    Language.knIN: cstring"India - Kannada",
    Language.koKR: cstring"Korea - Korean",
    Language.kokIN: cstring"India - Konkani",
    Language.kyKG: cstring"Kyrgyzstan - Kyrgyz",
    Language.lbLU: cstring"Luxembourg - Luxembourgish",
    Language.loLA: cstring"Lao P.D.R. - Lao",
    Language.ltLT: cstring"Lithuania - Lithuanian",
    Language.lvLV: cstring"Latvia - Latvian",
    Language.miNZ: cstring"New Zealand - Maori",
    Language.mkMK: cstring"Macedonia (FYROM) - Macedonian (FYROM)",
    Language.mlIN: cstring"India - Malayalam",
    Language.mnCN: cstring"People's Republic of China - Mongolian (Traditional Mongolian)",
    Language.mnMN: cstring"Mongolia - Mongolian (Cyrillic)",
    Language.mohCA: cstring"Canada - Mohawk",
    Language.mrIN: cstring"India - Marathi",
    Language.msBN: cstring"Brunei Darussalam - Malay",
    Language.msMY: cstring"Malaysia - Malay",
    Language.mtMT: cstring"Malta - Maltese",
    Language.nbNO: cstring"Norway - Norwegian (Bokmal)",
    Language.neNP: cstring"Nepal - Nepali",
    Language.nlBE: cstring"Belgium - Dutch",
    Language.nlNL: cstring"Netherlands - Dutch",
    Language.nnNO: cstring"Norway - Norwegian (Nynorsk)",
    Language.nsoZA: cstring"South Africa - Sesotho sa Leboa",
    Language.ocFR: cstring"France - Occitan",
    Language.orIN: cstring"India - Oriya",
    Language.paIN: cstring"India - Punjabi",
    Language.plPL: cstring"Poland - Polish",
    Language.prsAF: cstring"Afghanistan - Dari",
    Language.psAF: cstring"Afghanistan - Pashto",
    Language.ptBR: cstring"Brazil - Portuguese",
    Language.ptPT: cstring"Portugal - Portuguese",
    Language.qutGT: cstring"Guatemala - K'iche",
    Language.quzBO: cstring"Bolivia - Quechua",
    Language.quzEC: cstring"Ecuador - Quechua",
    Language.quzPE: cstring"Peru - Quechua",
    Language.rmCH: cstring"Switzerland - Romansh",
    Language.roRO: cstring"Romania - Romanian",
    Language.ruRU: cstring"Russia - Russian",
    Language.rwRW: cstring"Rwanda - Kinyarwanda",
    Language.saIN: cstring"India - Sanskrit",
    Language.sahRU: cstring"Russia - Yakut",
    Language.seFI: cstring"Finland - Sami (Northern)",
    Language.seNO: cstring"Norway - Sami (Northern)",
    Language.seSE: cstring"Sweden - Sami (Northern)",
    Language.siLK: cstring"Sri Lanka - Sinhala",
    Language.skSK: cstring"Slovakia - Slovak",
    Language.slSI: cstring"Slovenia - Slovenian",
    Language.smaNO: cstring"Norway - Sami (Southern)",
    Language.smaSE: cstring"Sweden - Sami (Southern)",
    Language.smjNO: cstring"Norway - Sami (Lule)",
    Language.smjSE: cstring"Sweden - Sami (Lule)",
    Language.smnFI: cstring"Finland - Sami (Inari)",
    Language.smsFI: cstring"Finland - Sami (Skolt)",
    Language.sqAL: cstring"Albania - Albanian",
    Language.srBA: cstring"Bosnia and Herzegovina - Serbian (Cyrillic)",
    Language.srCS: cstring"Serbia and Montenegro (Former) - Serbian (Cyrillic)",
    Language.srME: cstring"Montenegro - Serbian (Cyrillic)",
    Language.srRS: cstring"Serbia - Serbian (Cyrillic)",
    Language.svFI: cstring"Finland - Swedish",
    Language.svSE: cstring"Sweden - Swedish",
    Language.swKE: cstring"Kenya - Kiswahili",
    Language.syrSY: cstring"Syria - Syriac",
    Language.taIN: cstring"India - Tamil",
    Language.teIN: cstring"India - Telugu",
    Language.tgTJ: cstring"Tajikistan - Tajik (Cyrillic)",
    Language.thTH: cstring"Thailand - Thai",
    Language.tkTM: cstring"Turkmenistan - Turkmen",
    Language.tnZA: cstring"South Africa - Setswana",
    Language.trTR: cstring"Turkey - Turkish",
    Language.ttRU: cstring"Russia - Tatar",
    Language.tzmDZ: cstring"Algeria - Tamazight (Latin)",
    Language.ugCN: cstring"People's Republic of China - Uyghur",
    Language.ukUA: cstring"Ukraine - Ukrainian",
    Language.urPK: cstring"Islamic Republic of Pakistan - Urdu",
    Language.uzUZ: cstring"Uzbekistan - Uzbek (Cyrillic)",
    Language.viVN: cstring"Vietnam - Vietnamese",
    Language.woSN: cstring"Senegal - Wolof",
    Language.xhZA: cstring"South Africa - isiXhosa",
    Language.yoNG: cstring"Nigeria - Yoruba",
    Language.zhCN: cstring"People's Republic of China - Chinese (Simplified) Legacy",
    Language.zhHK: cstring"Hong Kong S.A.R. - Chinese (Traditional) Legacy",
    Language.zhMO: cstring"Macao S.A.R. - Chinese (Traditional) Legacy",
    Language.zhSG: cstring"Singapore - Chinese (Simplified) Legacy",
    Language.zhTW: cstring"Taiwan - Chinese (Traditional) Legacy",
    Language.zuZA: cstring"South Africa - isiZulu"]

  languageToCode*: array[Language, cstring] = [
    Language.afZA: cstring"af-ZA",
    Language.amET: cstring"am-ET",
    Language.arAE: cstring"ar-AE",
    Language.arBH: cstring"ar-BH",
    Language.arDZ: cstring"ar-DZ",
    Language.arEG: cstring"ar-EG",
    Language.arIQ: cstring"ar-IQ",
    Language.arJO: cstring"ar-JO",
    Language.arKW: cstring"ar-KW",
    Language.arLB: cstring"ar-LB",
    Language.arLY: cstring"ar-LY",
    Language.arMA: cstring"ar-MA",
    Language.arOM: cstring"ar-OM",
    Language.arQA: cstring"ar-QA",
    Language.arSA: cstring"ar-SA",
    Language.arSY: cstring"ar-SY",
    Language.arTN: cstring"ar-TN",
    Language.arYE: cstring"ar-YE",
    Language.arnCL: cstring"arn-CL",
    Language.asIN: cstring"as-IN",
    Language.azAZ: cstring"az-AZ",
    Language.baRU: cstring"ba-RU",
    Language.beBY: cstring"be-BY",
    Language.bgBG: cstring"bg-BG",
    Language.bnBD: cstring"bn-BD",
    Language.bnIN: cstring"bn-IN",
    Language.boCN: cstring"bo-CN",
    Language.brFR: cstring"br-FR",
    Language.bsBA: cstring"bs-BA",
    Language.caES: cstring"ca-ES",
    Language.coFR: cstring"co-FR",
    Language.csCZ: cstring"cs-CZ",
    Language.cyGB: cstring"cy-GB",
    Language.daDK: cstring"da-DK",
    Language.deAT: cstring"de-AT",
    Language.deCH: cstring"de-CH",
    Language.deDE: cstring"de-DE",
    Language.deLI: cstring"de-LI",
    Language.deLU: cstring"de-LU",
    Language.dsbDE: cstring"dsb-DE",
    Language.dvMV: cstring"dv-MV",
    Language.elGR: cstring"el-GR",
    Language.en029: cstring"en-029",
    Language.enAU: cstring"en-AU",
    Language.enBZ: cstring"en-BZ",
    Language.enCA: cstring"en-CA",
    Language.enGB: cstring"en-GB",
    Language.enIE: cstring"en-IE",
    Language.enIN: cstring"en-IN",
    Language.enJM: cstring"en-JM",
    Language.enMY: cstring"en-MY",
    Language.enNZ: cstring"en-NZ",
    Language.enPH: cstring"en-PH",
    Language.enSG: cstring"en-SG",
    Language.enTT: cstring"en-TT",
    Language.enUS: cstring"en-US",
    Language.enZA: cstring"en-ZA",
    Language.enZW: cstring"en-ZW",
    Language.esAR: cstring"es-AR",
    Language.esBO: cstring"es-BO",
    Language.esCL: cstring"es-CL",
    Language.esCO: cstring"es-CO",
    Language.esCR: cstring"es-CR",
    Language.esDO: cstring"es-DO",
    Language.esEC: cstring"es-EC",
    Language.esES: cstring"es-ES",
    Language.esGT: cstring"es-GT",
    Language.esHN: cstring"es-HN",
    Language.esMX: cstring"es-MX",
    Language.esNI: cstring"es-NI",
    Language.esPA: cstring"es-PA",
    Language.esPE: cstring"es-PE",
    Language.esPR: cstring"es-PR",
    Language.esPY: cstring"es-PY",
    Language.esSV: cstring"es-SV",
    Language.esUS: cstring"es-US",
    Language.esUY: cstring"es-UY",
    Language.esVE: cstring"es-VE",
    Language.etEE: cstring"et-EE",
    Language.euES: cstring"eu-ES",
    Language.faIR: cstring"fa-IR",
    Language.fiFI: cstring"fi-FI",
    Language.filPH: cstring"fil-PH",
    Language.foFO: cstring"fo-FO",
    Language.frBE: cstring"fr-BE",
    Language.frCA: cstring"fr-CA",
    Language.frCH: cstring"fr-CH",
    Language.frFR: cstring"fr-FR",
    Language.frLU: cstring"fr-LU",
    Language.frMC: cstring"fr-MC",
    Language.fyNL: cstring"fy-NL",
    Language.gaIE: cstring"ga-IE",
    Language.gdGB: cstring"gd-GB",
    Language.glES: cstring"gl-ES",
    Language.gswFR: cstring"gsw-FR",
    Language.guIN: cstring"gu-IN",
    Language.haNG: cstring"ha-NG",
    Language.heIL: cstring"he-IL",
    Language.hiIN: cstring"hi-IN",
    Language.hrBA: cstring"hr-BA",
    Language.hrHR: cstring"hr-HR",
    Language.hsbDE: cstring"hsb-DE",
    Language.huHU: cstring"hu-HU",
    Language.hyAM: cstring"hy-AM",
    Language.idID: cstring"id-ID",
    Language.igNG: cstring"ig-NG",
    Language.iiCN: cstring"ii-CN",
    Language.isIS: cstring"is-IS",
    Language.itCH: cstring"it-CH",
    Language.itIT: cstring"it-IT",
    Language.iuCA: cstring"iu-CA",
    Language.jaJP: cstring"ja-JP",
    Language.kaGE: cstring"ka-GE",
    Language.kkKZ: cstring"kk-KZ",
    Language.klGL: cstring"kl-GL",
    Language.kmKH: cstring"km-KH",
    Language.knIN: cstring"kn-IN",
    Language.koKR: cstring"ko-KR",
    Language.kokIN: cstring"kok-IN",
    Language.kyKG: cstring"ky-KG",
    Language.lbLU: cstring"lb-LU",
    Language.loLA: cstring"lo-LA",
    Language.ltLT: cstring"lt-LT",
    Language.lvLV: cstring"lv-LV",
    Language.miNZ: cstring"mi-NZ",
    Language.mkMK: cstring"mk-MK",
    Language.mlIN: cstring"ml-IN",
    Language.mnCN: cstring"mn-CN",
    Language.mnMN: cstring"mn-MN",
    Language.mohCA: cstring"moh-CA",
    Language.mrIN: cstring"mr-IN",
    Language.msBN: cstring"ms-BN",
    Language.msMY: cstring"ms-MY",
    Language.mtMT: cstring"mt-MT",
    Language.nbNO: cstring"nb-NO",
    Language.neNP: cstring"ne-NP",
    Language.nlBE: cstring"nl-BE",
    Language.nlNL: cstring"nl-NL",
    Language.nnNO: cstring"nn-NO",
    Language.nsoZA: cstring"nso-ZA",
    Language.ocFR: cstring"oc-FR",
    Language.orIN: cstring"or-IN",
    Language.paIN: cstring"pa-IN",
    Language.plPL: cstring"pl-PL",
    Language.prsAF: cstring"prs-AF",
    Language.psAF: cstring"ps-AF",
    Language.ptBR: cstring"pt-BR",
    Language.ptPT: cstring"pt-PT",
    Language.qutGT: cstring"qut-GT",
    Language.quzBO: cstring"quz-BO",
    Language.quzEC: cstring"quz-EC",
    Language.quzPE: cstring"quz-PE",
    Language.rmCH: cstring"rm-CH",
    Language.roRO: cstring"ro-RO",
    Language.ruRU: cstring"ru-RU",
    Language.rwRW: cstring"rw-RW",
    Language.saIN: cstring"sa-IN",
    Language.sahRU: cstring"sah-RU",
    Language.seFI: cstring"se-FI",
    Language.seNO: cstring"se-NO",
    Language.seSE: cstring"se-SE",
    Language.siLK: cstring"si-LK",
    Language.skSK: cstring"sk-SK",
    Language.slSI: cstring"sl-SI",
    Language.smaNO: cstring"sma-NO",
    Language.smaSE: cstring"sma-SE",
    Language.smjNO: cstring"smj-NO",
    Language.smjSE: cstring"smj-SE",
    Language.smnFI: cstring"smn-FI",
    Language.smsFI: cstring"sms-FI",
    Language.sqAL: cstring"sq-AL",
    Language.srBA: cstring"sr-BA",
    Language.srCS: cstring"sr-CS",
    Language.srME: cstring"sr-ME",
    Language.srRS: cstring"sr-RS",
    Language.svFI: cstring"sv-FI",
    Language.svSE: cstring"sv-SE",
    Language.swKE: cstring"sw-KE",
    Language.syrSY: cstring"syr-SY",
    Language.taIN: cstring"ta-IN",
    Language.teIN: cstring"te-IN",
    Language.tgTJ: cstring"tg-TJ",
    Language.thTH: cstring"th-TH",
    Language.tkTM: cstring"tk-TM",
    Language.tnZA: cstring"tn-ZA",
    Language.trTR: cstring"tr-TR",
    Language.ttRU: cstring"tt-RU",
    Language.tzmDZ: cstring"tzm-DZ",
    Language.ugCN: cstring"ug-CN",
    Language.ukUA: cstring"uk-UA",
    Language.urPK: cstring"ur-PK",
    Language.uzUZ: cstring"uz-UZ",
    Language.viVN: cstring"vi-VN",
    Language.woSN: cstring"wo-SN",
    Language.xhZA: cstring"xh-ZA",
    Language.yoNG: cstring"yo-NG",
    Language.zhCN: cstring"zh-CN",
    Language.zhHK: cstring"zh-HK",
    Language.zhMO: cstring"zh-MO",
    Language.zhSG: cstring"zh-SG",
    Language.zhTW: cstring"zh-TW",
    Language.zuZA: cstring"zu-ZA"]
