## Karax -- Single page applications for Nim.

import kbase

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
  languageToName*: array[Language, kstring] = [
    Language.afZA: kstring"South Africa - Afrikaans",
    Language.amET: kstring"Ethiopia - Amharic",
    Language.arAE: kstring"U.A.E. - Arabic",
    Language.arBH: kstring"Bahrain - Arabic",
    Language.arDZ: kstring"Algeria - Arabic",
    Language.arEG: kstring"Egypt - Arabic",
    Language.arIQ: kstring"Iraq - Arabic",
    Language.arJO: kstring"Jordan - Arabic",
    Language.arKW: kstring"Kuwait - Arabic",
    Language.arLB: kstring"Lebanon - Arabic",
    Language.arLY: kstring"Libya - Arabic",
    Language.arMA: kstring"Morocco - Arabic",
    Language.arOM: kstring"Oman - Arabic",
    Language.arQA: kstring"Qatar - Arabic",
    Language.arSA: kstring"Saudi Arabia - Arabic",
    Language.arSY: kstring"Syria - Arabic",
    Language.arTN: kstring"Tunisia - Arabic",
    Language.arYE: kstring"Yemen - Arabic",
    Language.arnCL: kstring"Chile - Mapudungun",
    Language.asIN: kstring"India - Assamese",
    Language.azAZ: kstring"Azerbaijan - Azeri (Cyrillic)",
    Language.baRU: kstring"Russia - Bashkir",
    Language.beBY: kstring"Belarus - Belarusian",
    Language.bgBG: kstring"Bulgaria - Bulgarian",
    Language.bnBD: kstring"Bangladesh - Bengali",
    Language.bnIN: kstring"India - Bengali",
    Language.boCN: kstring"People's Republic of China - Tibetan",
    Language.brFR: kstring"France - Breton",
    Language.bsBA: kstring"Bosnia and Herzegovina - Bosnian (Cyrillic)",
    Language.caES: kstring"Spain - Catalan",
    Language.coFR: kstring"France - Corsican",
    Language.csCZ: kstring"Czech Republic - Czech",
    Language.cyGB: kstring"United Kingdom - Welsh",
    Language.daDK: kstring"Denmark - Danish",
    Language.deAT: kstring"Austria - German",
    Language.deCH: kstring"Switzerland - German",
    Language.deDE: kstring"Germany - German",
    Language.deLI: kstring"Liechtenstein - German",
    Language.deLU: kstring"Luxembourg - German",
    Language.dsbDE: kstring"Germany - Lower Sorbian",
    Language.dvMV: kstring"Maldives - Divehi",
    Language.elGR: kstring"Greece - Greek",
    Language.en029: kstring"Caribbean - English",
    Language.enAU: kstring"Australia - English",
    Language.enBZ: kstring"Belize - English",
    Language.enCA: kstring"Canada - English",
    Language.enGB: kstring"United Kingdom - English",
    Language.enIE: kstring"Ireland - English",
    Language.enIN: kstring"India - English",
    Language.enJM: kstring"Jamaica - English",
    Language.enMY: kstring"Malaysia - English",
    Language.enNZ: kstring"New Zealand - English",
    Language.enPH: kstring"Republic of the Philippines - English",
    Language.enSG: kstring"Singapore - English",
    Language.enTT: kstring"Trinidad and Tobago - English",
    Language.enUS: kstring"United States - English",
    Language.enZA: kstring"South Africa - English",
    Language.enZW: kstring"Zimbabwe - English",
    Language.esAR: kstring"Argentina - Spanish",
    Language.esBO: kstring"Bolivia - Spanish",
    Language.esCL: kstring"Chile - Spanish",
    Language.esCO: kstring"Colombia - Spanish",
    Language.esCR: kstring"Costa Rica - Spanish",
    Language.esDO: kstring"Dominican Republic - Spanish",
    Language.esEC: kstring"Ecuador - Spanish",
    Language.esES: kstring"Spain - Spanish",
    Language.esGT: kstring"Guatemala - Spanish",
    Language.esHN: kstring"Honduras - Spanish",
    Language.esMX: kstring"Mexico - Spanish",
    Language.esNI: kstring"Nicaragua - Spanish",
    Language.esPA: kstring"Panama - Spanish",
    Language.esPE: kstring"Peru - Spanish",
    Language.esPR: kstring"Puerto Rico - Spanish",
    Language.esPY: kstring"Paraguay - Spanish",
    Language.esSV: kstring"El Salvador - Spanish",
    Language.esUS: kstring"United States - Spanish",
    Language.esUY: kstring"Uruguay - Spanish",
    Language.esVE: kstring"Bolivarian Republic of Venezuela - Spanish",
    Language.etEE: kstring"Estonia - Estonian",
    Language.euES: kstring"Spain - Basque",
    Language.faIR: kstring"Iran - Persian",
    Language.fiFI: kstring"Finland - Finnish",
    Language.filPH: kstring"Philippines - Filipino",
    Language.foFO: kstring"Faroe Islands - Faroese",
    Language.frBE: kstring"Belgium - French",
    Language.frCA: kstring"Canada - French",
    Language.frCH: kstring"Switzerland - French",
    Language.frFR: kstring"France - French",
    Language.frLU: kstring"Luxembourg - French",
    Language.frMC: kstring"Principality of Monaco - French",
    Language.fyNL: kstring"Netherlands - Frisian",
    Language.gaIE: kstring"Ireland - Irish",
    Language.gdGB: kstring"United Kingdom - Scottish Gaelic",
    Language.glES: kstring"Spain - Galician",
    Language.gswFR: kstring"France - Alsatian",
    Language.guIN: kstring"India - Gujarati",
    Language.haNG: kstring"Nigeria - Hausa (Latin)",
    Language.heIL: kstring"Israel - Hebrew",
    Language.hiIN: kstring"India - Hindi",
    Language.hrBA: kstring"Bosnia and Herzegovina - Croatian",
    Language.hrHR: kstring"Croatia - Croatian",
    Language.hsbDE: kstring"Germany - Upper Sorbian",
    Language.huHU: kstring"Hungary - Hungarian",
    Language.hyAM: kstring"Armenia - Armenian",
    Language.idID: kstring"Indonesia - Indonesian",
    Language.igNG: kstring"Nigeria - Igbo",
    Language.iiCN: kstring"People's Republic of China - Yi",
    Language.isIS: kstring"Iceland - Icelandic",
    Language.itCH: kstring"Switzerland - Italian",
    Language.itIT: kstring"Italy - Italian",
    Language.iuCA: kstring"Canada - Inuktitut (Latin)",
    Language.jaJP: kstring"Japan - Japanese",
    Language.kaGE: kstring"Georgia - Georgian",
    Language.kkKZ: kstring"Kazakhstan - Kazakh",
    Language.klGL: kstring"Greenland - Greenlandic",
    Language.kmKH: kstring"Cambodia - Khmer",
    Language.knIN: kstring"India - Kannada",
    Language.koKR: kstring"Korea - Korean",
    Language.kokIN: kstring"India - Konkani",
    Language.kyKG: kstring"Kyrgyzstan - Kyrgyz",
    Language.lbLU: kstring"Luxembourg - Luxembourgish",
    Language.loLA: kstring"Lao P.D.R. - Lao",
    Language.ltLT: kstring"Lithuania - Lithuanian",
    Language.lvLV: kstring"Latvia - Latvian",
    Language.miNZ: kstring"New Zealand - Maori",
    Language.mkMK: kstring"Macedonia (FYROM) - Macedonian (FYROM)",
    Language.mlIN: kstring"India - Malayalam",
    Language.mnCN: kstring"People's Republic of China - Mongolian (Traditional Mongolian)",
    Language.mnMN: kstring"Mongolia - Mongolian (Cyrillic)",
    Language.mohCA: kstring"Canada - Mohawk",
    Language.mrIN: kstring"India - Marathi",
    Language.msBN: kstring"Brunei Darussalam - Malay",
    Language.msMY: kstring"Malaysia - Malay",
    Language.mtMT: kstring"Malta - Maltese",
    Language.nbNO: kstring"Norway - Norwegian (Bokmal)",
    Language.neNP: kstring"Nepal - Nepali",
    Language.nlBE: kstring"Belgium - Dutch",
    Language.nlNL: kstring"Netherlands - Dutch",
    Language.nnNO: kstring"Norway - Norwegian (Nynorsk)",
    Language.nsoZA: kstring"South Africa - Sesotho sa Leboa",
    Language.ocFR: kstring"France - Occitan",
    Language.orIN: kstring"India - Oriya",
    Language.paIN: kstring"India - Punjabi",
    Language.plPL: kstring"Poland - Polish",
    Language.prsAF: kstring"Afghanistan - Dari",
    Language.psAF: kstring"Afghanistan - Pashto",
    Language.ptBR: kstring"Brazil - Portuguese",
    Language.ptPT: kstring"Portugal - Portuguese",
    Language.qutGT: kstring"Guatemala - K'iche",
    Language.quzBO: kstring"Bolivia - Quechua",
    Language.quzEC: kstring"Ecuador - Quechua",
    Language.quzPE: kstring"Peru - Quechua",
    Language.rmCH: kstring"Switzerland - Romansh",
    Language.roRO: kstring"Romania - Romanian",
    Language.ruRU: kstring"Russia - Russian",
    Language.rwRW: kstring"Rwanda - Kinyarwanda",
    Language.saIN: kstring"India - Sanskrit",
    Language.sahRU: kstring"Russia - Yakut",
    Language.seFI: kstring"Finland - Sami (Northern)",
    Language.seNO: kstring"Norway - Sami (Northern)",
    Language.seSE: kstring"Sweden - Sami (Northern)",
    Language.siLK: kstring"Sri Lanka - Sinhala",
    Language.skSK: kstring"Slovakia - Slovak",
    Language.slSI: kstring"Slovenia - Slovenian",
    Language.smaNO: kstring"Norway - Sami (Southern)",
    Language.smaSE: kstring"Sweden - Sami (Southern)",
    Language.smjNO: kstring"Norway - Sami (Lule)",
    Language.smjSE: kstring"Sweden - Sami (Lule)",
    Language.smnFI: kstring"Finland - Sami (Inari)",
    Language.smsFI: kstring"Finland - Sami (Skolt)",
    Language.sqAL: kstring"Albania - Albanian",
    Language.srBA: kstring"Bosnia and Herzegovina - Serbian (Cyrillic)",
    Language.srCS: kstring"Serbia and Montenegro (Former) - Serbian (Cyrillic)",
    Language.srME: kstring"Montenegro - Serbian (Cyrillic)",
    Language.srRS: kstring"Serbia - Serbian (Cyrillic)",
    Language.svFI: kstring"Finland - Swedish",
    Language.svSE: kstring"Sweden - Swedish",
    Language.swKE: kstring"Kenya - Kiswahili",
    Language.syrSY: kstring"Syria - Syriac",
    Language.taIN: kstring"India - Tamil",
    Language.teIN: kstring"India - Telugu",
    Language.tgTJ: kstring"Tajikistan - Tajik (Cyrillic)",
    Language.thTH: kstring"Thailand - Thai",
    Language.tkTM: kstring"Turkmenistan - Turkmen",
    Language.tnZA: kstring"South Africa - Setswana",
    Language.trTR: kstring"Turkey - Turkish",
    Language.ttRU: kstring"Russia - Tatar",
    Language.tzmDZ: kstring"Algeria - Tamazight (Latin)",
    Language.ugCN: kstring"People's Republic of China - Uyghur",
    Language.ukUA: kstring"Ukraine - Ukrainian",
    Language.urPK: kstring"Islamic Republic of Pakistan - Urdu",
    Language.uzUZ: kstring"Uzbekistan - Uzbek (Cyrillic)",
    Language.viVN: kstring"Vietnam - Vietnamese",
    Language.woSN: kstring"Senegal - Wolof",
    Language.xhZA: kstring"South Africa - isiXhosa",
    Language.yoNG: kstring"Nigeria - Yoruba",
    Language.zhCN: kstring"People's Republic of China - Chinese (Simplified) Legacy",
    Language.zhHK: kstring"Hong Kong S.A.R. - Chinese (Traditional) Legacy",
    Language.zhMO: kstring"Macao S.A.R. - Chinese (Traditional) Legacy",
    Language.zhSG: kstring"Singapore - Chinese (Simplified) Legacy",
    Language.zhTW: kstring"Taiwan - Chinese (Traditional) Legacy",
    Language.zuZA: kstring"South Africa - isiZulu"]

  languageToCode*: array[Language, kstring] = [
    Language.afZA: kstring"af-ZA",
    Language.amET: kstring"am-ET",
    Language.arAE: kstring"ar-AE",
    Language.arBH: kstring"ar-BH",
    Language.arDZ: kstring"ar-DZ",
    Language.arEG: kstring"ar-EG",
    Language.arIQ: kstring"ar-IQ",
    Language.arJO: kstring"ar-JO",
    Language.arKW: kstring"ar-KW",
    Language.arLB: kstring"ar-LB",
    Language.arLY: kstring"ar-LY",
    Language.arMA: kstring"ar-MA",
    Language.arOM: kstring"ar-OM",
    Language.arQA: kstring"ar-QA",
    Language.arSA: kstring"ar-SA",
    Language.arSY: kstring"ar-SY",
    Language.arTN: kstring"ar-TN",
    Language.arYE: kstring"ar-YE",
    Language.arnCL: kstring"arn-CL",
    Language.asIN: kstring"as-IN",
    Language.azAZ: kstring"az-AZ",
    Language.baRU: kstring"ba-RU",
    Language.beBY: kstring"be-BY",
    Language.bgBG: kstring"bg-BG",
    Language.bnBD: kstring"bn-BD",
    Language.bnIN: kstring"bn-IN",
    Language.boCN: kstring"bo-CN",
    Language.brFR: kstring"br-FR",
    Language.bsBA: kstring"bs-BA",
    Language.caES: kstring"ca-ES",
    Language.coFR: kstring"co-FR",
    Language.csCZ: kstring"cs-CZ",
    Language.cyGB: kstring"cy-GB",
    Language.daDK: kstring"da-DK",
    Language.deAT: kstring"de-AT",
    Language.deCH: kstring"de-CH",
    Language.deDE: kstring"de-DE",
    Language.deLI: kstring"de-LI",
    Language.deLU: kstring"de-LU",
    Language.dsbDE: kstring"dsb-DE",
    Language.dvMV: kstring"dv-MV",
    Language.elGR: kstring"el-GR",
    Language.en029: kstring"en-029",
    Language.enAU: kstring"en-AU",
    Language.enBZ: kstring"en-BZ",
    Language.enCA: kstring"en-CA",
    Language.enGB: kstring"en-GB",
    Language.enIE: kstring"en-IE",
    Language.enIN: kstring"en-IN",
    Language.enJM: kstring"en-JM",
    Language.enMY: kstring"en-MY",
    Language.enNZ: kstring"en-NZ",
    Language.enPH: kstring"en-PH",
    Language.enSG: kstring"en-SG",
    Language.enTT: kstring"en-TT",
    Language.enUS: kstring"en-US",
    Language.enZA: kstring"en-ZA",
    Language.enZW: kstring"en-ZW",
    Language.esAR: kstring"es-AR",
    Language.esBO: kstring"es-BO",
    Language.esCL: kstring"es-CL",
    Language.esCO: kstring"es-CO",
    Language.esCR: kstring"es-CR",
    Language.esDO: kstring"es-DO",
    Language.esEC: kstring"es-EC",
    Language.esES: kstring"es-ES",
    Language.esGT: kstring"es-GT",
    Language.esHN: kstring"es-HN",
    Language.esMX: kstring"es-MX",
    Language.esNI: kstring"es-NI",
    Language.esPA: kstring"es-PA",
    Language.esPE: kstring"es-PE",
    Language.esPR: kstring"es-PR",
    Language.esPY: kstring"es-PY",
    Language.esSV: kstring"es-SV",
    Language.esUS: kstring"es-US",
    Language.esUY: kstring"es-UY",
    Language.esVE: kstring"es-VE",
    Language.etEE: kstring"et-EE",
    Language.euES: kstring"eu-ES",
    Language.faIR: kstring"fa-IR",
    Language.fiFI: kstring"fi-FI",
    Language.filPH: kstring"fil-PH",
    Language.foFO: kstring"fo-FO",
    Language.frBE: kstring"fr-BE",
    Language.frCA: kstring"fr-CA",
    Language.frCH: kstring"fr-CH",
    Language.frFR: kstring"fr-FR",
    Language.frLU: kstring"fr-LU",
    Language.frMC: kstring"fr-MC",
    Language.fyNL: kstring"fy-NL",
    Language.gaIE: kstring"ga-IE",
    Language.gdGB: kstring"gd-GB",
    Language.glES: kstring"gl-ES",
    Language.gswFR: kstring"gsw-FR",
    Language.guIN: kstring"gu-IN",
    Language.haNG: kstring"ha-NG",
    Language.heIL: kstring"he-IL",
    Language.hiIN: kstring"hi-IN",
    Language.hrBA: kstring"hr-BA",
    Language.hrHR: kstring"hr-HR",
    Language.hsbDE: kstring"hsb-DE",
    Language.huHU: kstring"hu-HU",
    Language.hyAM: kstring"hy-AM",
    Language.idID: kstring"id-ID",
    Language.igNG: kstring"ig-NG",
    Language.iiCN: kstring"ii-CN",
    Language.isIS: kstring"is-IS",
    Language.itCH: kstring"it-CH",
    Language.itIT: kstring"it-IT",
    Language.iuCA: kstring"iu-CA",
    Language.jaJP: kstring"ja-JP",
    Language.kaGE: kstring"ka-GE",
    Language.kkKZ: kstring"kk-KZ",
    Language.klGL: kstring"kl-GL",
    Language.kmKH: kstring"km-KH",
    Language.knIN: kstring"kn-IN",
    Language.koKR: kstring"ko-KR",
    Language.kokIN: kstring"kok-IN",
    Language.kyKG: kstring"ky-KG",
    Language.lbLU: kstring"lb-LU",
    Language.loLA: kstring"lo-LA",
    Language.ltLT: kstring"lt-LT",
    Language.lvLV: kstring"lv-LV",
    Language.miNZ: kstring"mi-NZ",
    Language.mkMK: kstring"mk-MK",
    Language.mlIN: kstring"ml-IN",
    Language.mnCN: kstring"mn-CN",
    Language.mnMN: kstring"mn-MN",
    Language.mohCA: kstring"moh-CA",
    Language.mrIN: kstring"mr-IN",
    Language.msBN: kstring"ms-BN",
    Language.msMY: kstring"ms-MY",
    Language.mtMT: kstring"mt-MT",
    Language.nbNO: kstring"nb-NO",
    Language.neNP: kstring"ne-NP",
    Language.nlBE: kstring"nl-BE",
    Language.nlNL: kstring"nl-NL",
    Language.nnNO: kstring"nn-NO",
    Language.nsoZA: kstring"nso-ZA",
    Language.ocFR: kstring"oc-FR",
    Language.orIN: kstring"or-IN",
    Language.paIN: kstring"pa-IN",
    Language.plPL: kstring"pl-PL",
    Language.prsAF: kstring"prs-AF",
    Language.psAF: kstring"ps-AF",
    Language.ptBR: kstring"pt-BR",
    Language.ptPT: kstring"pt-PT",
    Language.qutGT: kstring"qut-GT",
    Language.quzBO: kstring"quz-BO",
    Language.quzEC: kstring"quz-EC",
    Language.quzPE: kstring"quz-PE",
    Language.rmCH: kstring"rm-CH",
    Language.roRO: kstring"ro-RO",
    Language.ruRU: kstring"ru-RU",
    Language.rwRW: kstring"rw-RW",
    Language.saIN: kstring"sa-IN",
    Language.sahRU: kstring"sah-RU",
    Language.seFI: kstring"se-FI",
    Language.seNO: kstring"se-NO",
    Language.seSE: kstring"se-SE",
    Language.siLK: kstring"si-LK",
    Language.skSK: kstring"sk-SK",
    Language.slSI: kstring"sl-SI",
    Language.smaNO: kstring"sma-NO",
    Language.smaSE: kstring"sma-SE",
    Language.smjNO: kstring"smj-NO",
    Language.smjSE: kstring"smj-SE",
    Language.smnFI: kstring"smn-FI",
    Language.smsFI: kstring"sms-FI",
    Language.sqAL: kstring"sq-AL",
    Language.srBA: kstring"sr-BA",
    Language.srCS: kstring"sr-CS",
    Language.srME: kstring"sr-ME",
    Language.srRS: kstring"sr-RS",
    Language.svFI: kstring"sv-FI",
    Language.svSE: kstring"sv-SE",
    Language.swKE: kstring"sw-KE",
    Language.syrSY: kstring"syr-SY",
    Language.taIN: kstring"ta-IN",
    Language.teIN: kstring"te-IN",
    Language.tgTJ: kstring"tg-TJ",
    Language.thTH: kstring"th-TH",
    Language.tkTM: kstring"tk-TM",
    Language.tnZA: kstring"tn-ZA",
    Language.trTR: kstring"tr-TR",
    Language.ttRU: kstring"tt-RU",
    Language.tzmDZ: kstring"tzm-DZ",
    Language.ugCN: kstring"ug-CN",
    Language.ukUA: kstring"uk-UA",
    Language.urPK: kstring"ur-PK",
    Language.uzUZ: kstring"uz-UZ",
    Language.viVN: kstring"vi-VN",
    Language.woSN: kstring"wo-SN",
    Language.xhZA: kstring"xh-ZA",
    Language.yoNG: kstring"yo-NG",
    Language.zhCN: kstring"zh-CN",
    Language.zhHK: kstring"zh-HK",
    Language.zhMO: kstring"zh-MO",
    Language.zhSG: kstring"zh-SG",
    Language.zhTW: kstring"zh-TW",
    Language.zuZA: kstring"zu-ZA"]
