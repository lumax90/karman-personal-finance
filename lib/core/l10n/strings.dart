import 'app_locale.dart';

class S {
  final AppLanguage _lang;
  const S(this._lang);

  String get appName => _t('Karman', 'Karman');

  // Navigation
  String get navDashboard => _t('Ozet', 'Overview');
  String get navTransactions => _t('Islemler', 'Transactions');
  String get navSubscriptions => _t('Abonelik', 'Subscriptions');
  String get navInsights => _t('Analiz', 'Insights');

  // Account
  String get personal => _t('Kisisel', 'Personal');
  String get business => _t('Isletme', 'Business');
  String get personalFinance => _t('Kisisel finans yonetimi', 'Personal finance management');
  String get businessFinance => _t('Isletme finans yonetimi', 'Business finance management');

  // Dashboard
  String get personalBalance => _t('Kisisel Bakiye', 'Personal Balance');
  String get businessBalance => _t('Isletme Bakiye', 'Business Balance');
  String get income => _t('Gelir', 'Income');
  String get expense => _t('Gider', 'Expense');
  String get subscriptionsLabel => _t('Abonelikler', 'Subscriptions');
  String get recurring => _t('Tekrar Eden', 'Recurring');
  String get monthly => _t('aylik', 'monthly');
  String get expenseBreakdown => _t('Gider Dagilimi', 'Expense Breakdown');
  String get recentTransactions => _t('Son Islemler', 'Recent Transactions');
  String transactionCount(int count) => _t('$count islem', '$count transactions');
  String get savingsRate => _t('Tasarruf Orani', 'Savings Rate');
  String get profitMargin => _t('Kar Marji', 'Profit Margin');

  // Transactions
  String get all => _t('Tumu', 'All');
  String get noTransactions => _t('Henuz islem yok', 'No transactions yet');
  String deleted(String name) => _t('$name silindi', '$name deleted');

  // Add transaction
  String get newTransaction => _t('Yeni Islem', 'New Transaction');
  String get title => _t('Baslik', 'Title');
  String get titleHint => _t('or. Market alisverisi', 'e.g. Grocery shopping');
  String get amount => _t('Tutar', 'Amount');
  String get category => _t('Kategori', 'Category');
  String get recurrence => _t('Tekrar', 'Recurrence');
  String get date => _t('Tarih', 'Date');
  String get noteOptional => _t('Not (opsiyonel)', 'Note (optional)');
  String get noteHint => _t('Ekstra bilgi...', 'Additional info...');
  String get save => _t('Kaydet', 'Save');

  // Recurrence types
  String get once => _t('Tek seferlik', 'One-time');
  String get daily => _t('Gunluk', 'Daily');
  String get weekly => _t('Haftalik', 'Weekly');
  String get monthlyRecurrence => _t('Aylik', 'Monthly');
  String get yearly => _t('Yillik', 'Yearly');

  // Subscriptions
  String get monthlyTotal => _t('Aylik Toplam', 'Monthly Total');
  String get yearlyTotal => _t('Yillik Toplam', 'Yearly Total');
  String get active => _t('Aktif', 'Active');
  String get inactive => _t('Pasif', 'Inactive');
  String get total => _t('Toplam', 'Total');
  String get activeSubscriptions => _t('Aktif Abonelikler', 'Active Subscriptions');
  String get inactiveSubscriptions => _t('Pasif Abonelikler', 'Inactive Subscriptions');
  String get newSubscription => _t('Yeni Abonelik', 'New Subscription');
  String get subscriptionName => _t('Abonelik Adi', 'Subscription Name');
  String get subscriptionNameHint => _t('or. Netflix, Spotify', 'e.g. Netflix, Spotify');
  String get categoryLabel => _t('Kategori', 'Category');
  String get categoryHint => _t('or. Eglence, Yazilim', 'e.g. Entertainment, Software');
  String get billingCycle => _t('Fatura Donemi', 'Billing Cycle');
  String get perMonth => _t('/ay', '/mo');

  // Insights
  String get financialHealth => _t('Finansal Saglik', 'Financial Health');
  String get businessHealth => _t('Isletme Sagligi', 'Business Health');
  String get excellent => _t('Mukemmel', 'Excellent');
  String get good => _t('Iyi', 'Good');
  String get caution => _t('Dikkat', 'Caution');
  String get critical => _t('Kritik', 'Critical');
  String savingsMessage(int pct) =>
      _t('Gelirlerinizin %$pct\'${pct > 1 ? "i" : "i"} tasarruf ediliyor',
         '$pct% of your income is being saved');
  String profitMessage(int pct) =>
      _t('Gelirlerinizin %$pct\'${pct > 1 ? "i" : "i"} kar olarak kaliyor',
         '$pct% of your revenue remains as profit');
  String get incomeVsExpense => _t('Gelir vs Gider', 'Income vs Expense');
  String get keyMetrics => _t('Temel Metrikler', 'Key Metrics');
  String get recurringIncome => _t('Tekrar Eden Gelir', 'Recurring Income');
  String get recurringExpense => _t('Tekrar Eden Gider', 'Recurring Expense');
  String get subscriptionExpenseMonthly => _t('Abonelik Gideri (Aylik)', 'Subscription Expense (Monthly)');
  String get netCashFlow => _t('Net Nakit Akisi', 'Net Cash Flow');
  String get mandatoryExpenseRatio => _t('Zorunlu Gider Orani', 'Mandatory Expense Ratio');
  String get suggestions => _t('Oneriler', 'Suggestions');

  // Insight tips
  String get tipSavingsLow => _t(
    'Tasarruf oraninizi %20 uzerine cikarmaya hedefleyin.',
    'Aim to increase your savings rate above 20%.',
  );
  String tipSubsHigh(String amount) => _t(
    'Aylik abonelik giderleriniz $amount. Kullanmadiklarinizi iptal etmeyi dusunun.',
    'Your monthly subscription cost is $amount. Consider canceling unused ones.',
  );
  String get tipEmergencyFund => _t(
    'Acil durum fonu olarak 3-6 aylik giderinizi biriktirmeyi hedefleyin.',
    'Aim to save 3-6 months of expenses as an emergency fund.',
  );
  String get tipProfitLow => _t(
    'Kar marjiniz dusuk. Fiyatlandirma stratejinizi gozden gecirin.',
    'Your profit margin is low. Review your pricing strategy.',
  );
  String get tipRecurringRevenue => _t(
    'Tekrar eden gelir kaynaklarinizi artirmaya odaklanin.',
    'Focus on increasing your recurring revenue sources.',
  );
  String get tipOptimizeSoftware => _t(
    'Yazilim giderlerinizi optimize edebilirsiniz. Alternatifleri arastirin.',
    'You can optimize your software costs. Research alternatives.',
  );

  // Settings
  String get settings => _t('Ayarlar', 'Settings');
  String get language => _t('Dil', 'Language');
  String get turkish => _t('Turkce', 'Turkish');
  String get english => _t('Ingilizce', 'English');
  String get appearance => _t('Gorunum', 'Appearance');
  String get general => _t('Genel', 'General');

  // CRM Navigation (business mode)
  String get navContacts => _t('Kisiler', 'Contacts');
  String get navInvoices => _t('Faturalar', 'Invoices');
  String get navPipeline => _t('Pipeline', 'Pipeline');

  // Contacts
  String get searchContacts => _t('Kisi ara...', 'Search contacts...');
  String get leads => _t('Adaylar', 'Leads');
  String get clients => _t('Musteriler', 'Clients');
  String get lead => _t('Aday', 'Lead');
  String get client => _t('Musteri', 'Client');
  String get noContacts => _t('Henuz kisi yok', 'No contacts yet');
  String get convertToClient => _t('Musteriye Cevir', 'Convert to Client');
  String get status => _t('Durum', 'Status');
  String get source => _t('Kaynak', 'Source');
  String get totalRevenue => _t('Toplam Gelir', 'Total Revenue');
  String get createdAt => _t('Olusturulma', 'Created');
  String get lastContacted => _t('Son Iletisim', 'Last Contact');
  String get deals => _t('Firsatlar', 'Deals');
  String get invoices => _t('Faturalar', 'Invoices');
  String get activityHistory => _t('Aktivite Gecmisi', 'Activity History');
  String get noActivities => _t('Henuz aktivite yok', 'No activities yet');
  String get probability => _t('olasilik', 'probability');

  // Invoices
  String get receivable => _t('Alacak', 'Receivable');
  String get collected => _t('Tahsil', 'Collected');
  String get overdue => _t('Gecikmi\u015f', 'Overdue');
  String get unpaid => _t('Odenmemis', 'Unpaid');
  String get paidStatus => _t('Odenmis', 'Paid');
  String get draftStatus => _t('Taslak', 'Draft');
  String get noInvoices => _t('Henuz fatura yok', 'No invoices yet');
  String get subtotal => _t('Ara Toplam', 'Subtotal');
  String get tax => _t('KDV', 'Tax');
  String get send => _t('Gonder', 'Send');
  String get markPaid => _t('Odendi', 'Mark Paid');

  // Pipeline / Deals
  String get pipelineOverview => _t('Pipeline Ozeti', 'Pipeline Overview');
  String get pipelineValue => _t('Pipeline Degeri', 'Pipeline Value');
  String get weightedValue => _t('Agirlikli Deger', 'Weighted Value');
  String get wonRevenue => _t('Kazanilan', 'Won Revenue');
  String get winRate => _t('Kazanma Orani', 'Win Rate');
  String get expectedClose => _t('Beklenen', 'Expected');
  String get advance => _t('Ilerlet', 'Advance');
  String get closeWon => _t('Kazandik', 'Won');
  String get closeLost => _t('Kaybettik', 'Lost');
  String get closedDeals => _t('Kapanan Firsatlar', 'Closed Deals');

  // AI Smart Insights
  String get aiInsights => _t('Akilli Oneriler', 'Smart Insights');
  String get aiAlertHighExpense => _t('Yuksek Harcama Uyarisi', 'High Spending Alert');
  String aiAlertHighExpenseDesc(String total, String rate) => _t(
    'Toplam gideriniz $total. Tasarruf oraniniz sadece $rate. Harcamalarinizi gozden gecirin.',
    'Total expenses are $total. Your savings rate is only $rate. Review your spending.',
  );
  String get aiAchieveSavings => _t('Harika Tasarruf!', 'Great Savings!');
  String aiAchieveSavingsDesc(String rate) => _t(
    'Tasarruf oraniniz $rate - bu cok basarili. Boyle devam edin!',
    'Your savings rate is $rate - that\'s excellent. Keep it up!',
  );
  String get aiWarnSubs => _t('Abonelik Giderleri Yuksek', 'High Subscription Costs');
  String aiWarnSubsDesc(String monthly, String yearly) => _t(
    'Aylik $monthly (yillik $yearly) abonelik oduyorsunuz. Kullanmadiklarinizi iptal edin.',
    'You pay $monthly monthly ($yearly yearly) in subscriptions. Cancel unused ones.',
  );
  String get aiTrendRecurring => _t('Tekrar Eden Gider Orani Yuksek', 'High Recurring Expense Ratio');
  String aiTrendRecurringDesc(String pct) => _t(
    'Giderlerinizin $pct\'i tekrar eden. Sabit giderlerinizi azaltmayi deneyin.',
    '$pct of your expenses are recurring. Try reducing fixed costs.',
  );
  String get aiTrendTopCategory => _t('En Buyuk Gider Kategorisi', 'Top Expense Category');
  String aiTrendTopCategoryDesc(String cat, String amount, String pct) => _t(
    '$cat kategorisinde $amount harcadiniz (toplamin $pct\'i).',
    'You spent $amount on $cat ($pct of total).',
  );
  String get aiPipelineHealth => _t('Pipeline Durumu', 'Pipeline Health');
  String aiPipelineHealthDesc(String value, String winRate) => _t(
    'Pipeline degeriniz $value, kazanma oraniniz $winRate. Acik firsatlari takip edin.',
    'Pipeline value is $value, win rate is $winRate. Follow up on open deals.',
  );
  String get aiOverdueInvoices => _t('Gecikmi\u015f Faturalar', 'Overdue Invoices');
  String aiOverdueInvoicesDesc(String amount) => _t(
    '$amount tutarinda gecikmi\u015f fatura var. Hemen tahsilat baslatin.',
    'You have $amount in overdue invoices. Start collection immediately.',
  );
  String get aiReceivable => _t('Bekleyen Alacaklar', 'Pending Receivables');
  String aiReceivableDesc(String amount) => _t(
    '$amount alacaginiz var. Nakit akisinizi planlayin.',
    'You have $amount in receivables. Plan your cash flow.',
  );
  String get aiNewLeads => _t('Yeni Adaylar', 'New Leads');
  String aiNewLeadsDesc(int count) => _t(
    '$count aday bekliyor. Onlari degerlendirmeye alin.',
    '$count leads awaiting attention. Start qualifying them.',
  );
  String get aiEmergencyFund => _t('Acil Durum Fonu', 'Emergency Fund');
  String aiEmergencyFundDesc(String current, String target) => _t(
    'Mevcut birikiminiz $current. Hedef: $target (6 aylik gider).',
    'Current savings: $current. Target: $target (6 months expenses).',
  );

  // Goals
  String get goals => _t('Hedefler', 'Goals');
  String get noGoals => _t('Henuz hedef yok', 'No goals yet');
  String get newGoal => _t('Yeni Hedef', 'New Goal');
  String get goalName => _t('Hedef Adi', 'Goal Name');
  String get targetAmount => _t('Hedef Tutar', 'Target Amount');
  String get goalProgress => _t('Ilerleme', 'Progress');
  String get goalCompleted => _t('Tamamlandi', 'Completed');
  String get goalRemaining => _t('Kalan', 'Remaining');
  String get goalType => _t('Hedef Tipi', 'Goal Type');
  String get goalSavings => _t('Tasarruf', 'Savings');
  String get goalRevenue => _t('Gelir', 'Revenue');
  String get goalProfit => _t('Kar', 'Profit');
  String get goalExpenseLimit => _t('Gider Limiti', 'Expense Limit');

  // Reminders
  String get reminders => _t('Hatirlaticilar', 'Reminders');
  String get noReminders => _t('Hatirlatici yok', 'No reminders');
  String get overdueTasks => _t('Gecikmi\u015f', 'Overdue');
  String get upcoming => _t('Yaklasan', 'Upcoming');
  String get completed => _t('Tamamlanan', 'Completed');
  String get today => _t('Bugun', 'Today');
  String get markDone => _t('Tamamla', 'Mark Done');

  // Quick Actions
  String get quickActions => _t('Hizli Islem', 'Quick Actions');
  String get addIncome => _t('Gelir Ekle', 'Add Income');
  String get addExpense => _t('Gider Ekle', 'Add Expense');
  String get addContact => _t('Kisi Ekle', 'Add Contact');
  String get addDeal => _t('Firsat Ekle', 'Add Deal');

  // Reports
  String get reports => _t('Raporlar', 'Reports');
  String get monthlyReport => _t('Aylik Rapor', 'Monthly Report');
  String get incomeReport => _t('Gelir Raporu', 'Income Report');
  String get expenseReport => _t('Gider Raporu', 'Expense Report');
  String get exportPdf => _t('PDF Indir', 'Export PDF');
  String get exportExcel => _t('Excel Indir', 'Export Excel');
  String get shareReport => _t('Raporu Paylas', 'Share Report');
  String get period => _t('Donem', 'Period');
  String get summary => _t('Ozet', 'Summary');
  String get details => _t('Detay', 'Details');

  // Invoice PDF
  String get generatePdf => _t('PDF Olustur', 'Generate PDF');
  String get shareInvoice => _t('Faturayi Paylas', 'Share Invoice');
  String get invoiceDetails => _t('Fatura Detayi', 'Invoice Details');
  String get billTo => _t('Fatura Adresi', 'Bill To');
  String get invoiceDate => _t('Fatura Tarihi', 'Invoice Date');
  String get dueDate => _t('Vade Tarihi', 'Due Date');
  String get description => _t('Aciklama', 'Description');
  String get quantity => _t('Adet', 'Qty');
  String get unitPrice => _t('Birim Fiyat', 'Unit Price');
  String get totalLabel => _t('Toplam', 'Total');

  // AI Chat
  String get aiChat => _t('AI Asistan', 'AI Assistant');
  String get aiChatHint => _t('Finansal sorunuzu yazin...', 'Ask a financial question...');
  String get aiApiKeyRequired => _t('API anahtari gerekli — Ayarlar\'dan ekleyin', 'API key required — Add in Settings');
  String get aiPoweredBy => _t('Destekleyen:', 'Powered by');
  String get aiPrompt1 => _t('Bu ay ne kadar harcadim?', 'How much did I spend this month?');
  String get aiPrompt2 => _t('Tasarruf onerilerin neler?', 'What are your savings tips?');
  String get aiPrompt3 => _t('Finansal durumumu ozetle', 'Summarize my finances');

  // Premium / Paywall
  String get premiumRequired => _t('Premium Gerekli', 'Premium Required');
  String get premiumDesc => _t(
    'Bu model Premium abonelik gerektirir. Ucretsiz planda sadece Grok modelini kendi API anahtarinizla kullanabilirsiniz.',
    'This model requires a Premium subscription. On the free plan, you can only use Grok with your own API key.',
  );
  String get close => _t('Kapat', 'Close');
  String get free => _t('Ucretsiz', 'Free');
  String get premium => _t('Premium', 'Premium');
  String get currentPlan => _t('Mevcut Plan', 'Current Plan');

  // API Keys
  String get aiSettings => _t('AI Ayarlari', 'AI Settings');
  String get apiKey => _t('API Anahtari', 'API Key');
  String get apiKeyHint => _t('sk-... veya API anahtariniz', 'sk-... or your API key');
  String get apiKeySaved => _t('API anahtari kaydedildi', 'API key saved');
  String get modelSelection => _t('Model Secimi', 'Model Selection');
  String get freeWithOwnKey => _t('Ucretsiz (kendi anahtarinizla)', 'Free (with your own key)');
  String get premiumOnly => _t('Sadece Premium', 'Premium only');

  // Categories
  String categoryName(String key) {
    final map = _lang == AppLanguage.tr ? _categoryTr : _categoryEn;
    return map[key] ?? key;
  }

  // Month names
  String get currentMonth => _t('Subat 2026', 'February 2026');

  // Auth
  String get login => _t('Giris Yap', 'Login');
  String get register => _t('Kayit Ol', 'Register');
  String get loginSubtitle => _t('Hesabiniza giris yapin', 'Sign in to your account');
  String get registerSubtitle => _t('Yeni hesap olusturun', 'Create a new account');
  String get emailHint => _t('E-posta adresi', 'Email address');
  String get passwordHint => _t('Sifre', 'Password');
  String get confirmPasswordHint => _t('Sifre tekrar', 'Confirm password');
  String get nameHint => _t('Ad Soyad (istege bagli)', 'Full name (optional)');
  String get fieldRequired => _t('Bu alan zorunlu', 'This field is required');
  String get invalidEmail => _t('Gecerli bir e-posta girin', 'Enter a valid email');
  String get passwordTooShort => _t('Sifre en az 8 karakter olmali', 'Password must be at least 8 characters');
  String get passwordMismatch => _t('Sifreler eslesmiyor', 'Passwords do not match');
  String get noAccount => _t('Hesabiniz yok mu?', "Don't have an account?");
  String get haveAccount => _t('Zaten hesabiniz var mi?', 'Already have an account?');
  String get logoutConfirm => _t('Cikis yapmak istediginize emin misiniz?', 'Are you sure you want to logout?');
  String get logout => _t('Cikis Yap', 'Logout');
  String get cancel => _t('Iptal', 'Cancel');

  String _t(String tr, String en) => _lang == AppLanguage.tr ? tr : en;
}

const _categoryTr = {
  'salary': 'Maas',
  'freelance': 'Freelance',
  'investment': 'Yatirim',
  'rental': 'Kira Geliri',
  'otherIncome': 'Diger Gelir',
  'rent': 'Kira',
  'utilities': 'Faturalar',
  'groceries': 'Market',
  'transport': 'Ulasim',
  'entertainment': 'Eglence',
  'health': 'Saglik',
  'education': 'Egitim',
  'shopping': 'Alisveris',
  'food': 'Yemek',
  'sales': 'Satis',
  'service': 'Hizmet',
  'consulting': 'Danismanlik',
  'commission': 'Komisyon',
  'marketing': 'Pazarlama',
  'software': 'Yazilim',
  'hosting': 'Hosting',
  'office': 'Ofis',
  'equipment': 'Ekipman',
  'taxes': 'Vergi',
  'insurance': 'Sigorta',
  'payroll': 'Maas Odemesi',
  'subscription': 'Abonelik',
  'other': 'Diger',
};

const _categoryEn = {
  'salary': 'Salary',
  'freelance': 'Freelance',
  'investment': 'Investment',
  'rental': 'Rental Income',
  'otherIncome': 'Other Income',
  'rent': 'Rent',
  'utilities': 'Utilities',
  'groceries': 'Groceries',
  'transport': 'Transport',
  'entertainment': 'Entertainment',
  'health': 'Health',
  'education': 'Education',
  'shopping': 'Shopping',
  'food': 'Food',
  'sales': 'Sales',
  'service': 'Service',
  'consulting': 'Consulting',
  'commission': 'Commission',
  'marketing': 'Marketing',
  'software': 'Software',
  'hosting': 'Hosting',
  'office': 'Office',
  'equipment': 'Equipment',
  'taxes': 'Taxes',
  'insurance': 'Insurance',
  'payroll': 'Payroll',
  'subscription': 'Subscription',
  'other': 'Other',
};
