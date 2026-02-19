class ParsingConstants {
  // Locales to attempt date parsing with
  static const List<String> supportedLocales = [
    'en_US', 'en_GB', 'es_ES', 'fr_FR', 'de_DE', 'it_IT', 'pt_BR', 'pt_PT',
    'ja_JP', 'zh_CN', 'zh_TW', 'ko_KR', 'ru_RU', 'ar_SA', 'hi_IN', 'id_ID',
    'ms_MY', 'th_TH', 'vi_VN', 'tr_TR', 'pl_PL', 'cs_CZ', 'hu_HU', 'da_DK',
    'nb_NO', 'sv_SE', 'nl_NL', 'he_IL', 'fi_FI', 'ro_RO', 'el_GR'
  ];

  // CSV/PDF Header Keywords
  static const Set<String> dateKeywords = {
    'date', 'fecha', 'datum', 'data', 'tarih', 'tanggal', 'dátum', 'dato', 'pvm', 'ημερομηνία', '日期', '日付', '날짜', 'التاريخ'
  };

  static const Set<String> amountKeywords = {
    'amount', 'debit', 'value', 'price', 'cost', 'payment', 'withdrawal',
    'importe', 'monto', 'cargo', 'valor', 'cantidad',
    'betrag', 'wert', 'preis', 'auszahlung',
    'montant', 'prix', 'valeur', 'débit',
    'importo', 'costo', 'prezzo',
    'quantia', 'preço',
    'tutar', 'fiyat',
    'jumlah', 'harga', 'nilai',
    'összeg', 'částka', 'kwota',
    'beløb', 'belopp',
    'summa', 'сумма',
    '金额', '金額', '금액',
    'المبلغ', 'القيمة'
  };

  static const Set<String> descriptionKeywords = {
    'description', 'merchant', 'name', 'details', 'transaction', 'payee', 'beneficiary',
    'descripción', 'concepto', 'detalle', 'comercio', 'nombre',
    'beschreibung', 'verwendungszweck', 'text',
    'libellé', 'détails', 'commerçant',
    'descrizione', 'dettaglio', 'causale',
    'descrição', 'detalhe',
    'açıklama', 'detay',
    'uraian', 'keterangan', 'deskripsi',
    'leírás', 'popis', 'opis',
    'beskrivelse', 'beskrivning',
    'opisanio', 'описание', 'назначение',
    '描述', '说明', '説明', '내역',
    'الوصف', 'البيان'
  };
}
