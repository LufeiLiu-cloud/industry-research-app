import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '行研通',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// 数据模型
class IndustryData {
  final String industry;
  final int totalCompanies;
  final String avgCapital;
  final List<Company> companies;

  IndustryData({
    required this.industry,
    required this.totalCompanies,
    required this.avgCapital,
    required this.companies,
  });

  factory IndustryData.fromJson(Map<String, dynamic> json) {
    var companiesList = (json['market_overview']['leading_companies'] as List)
        .map((c) => Company.fromJson(c))
        .toList();
    
    return IndustryData(
      industry: json['industry'],
      totalCompanies: json['market_overview']['total_companies_found'],
      avgCapital: json['market_overview']['avg_registered_capital'],
      companies: companiesList,
    );
  }
}

class Company {
  final String name;
  final String legalPerson;
  final String capital;
  final int matchScore;

  Company({
    required this.name,
    required this.legalPerson,
    required this.capital,
    required this.matchScore,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'],
      legalPerson: json['legalPerson'],
      capital: json['capital'],
      matchScore: json['matchScore'],
    );
  }
}

// API服务
class ApiService {
  static const String baseUrl = 'https://tyc-api-rzmctvjimt.cn-hangzhou.fcapp.run';

  static Future<IndustryData> getIndustryData(String industry) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/industry-analysis'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'industry': industry}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return IndustryData.fromJson(data['data']);
      }
    }
    throw Exception('获取数据失败');
  }
}

// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _hotIndustries = ['新能源汽车', 'AI芯片', '生物医药', '预制菜'];

  void _search(String industry) {
    if (industry.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoadingScreen(industry: industry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Icon(Icons.analytics, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('行研通', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('智能行业投资分析', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '输入行业名称',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => _search(_controller.text),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: _search,
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('热门行业', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _hotIndustries.map((industry) {
                  return ActionChip(
                    label: Text(industry),
                    onPressed: () => _search(industry),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 加载页
class LoadingScreen extends StatefulWidget {
  final String industry;
  const LoadingScreen({super.key, required this.industry});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.getIndustryData(widget.industry);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ReportScreen(data: data)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('错误: $e'), action: SnackBarAction(label: '重试', onPressed: _loadData)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text('正在分析 ${widget.industry}...'),
          ],
        ),
      ),
    );
  }
}

// 报告页
class ReportScreen extends StatelessWidget {
  final IndustryData data;
  const ReportScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${data.industry}分析报告'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '概况'),
              Tab(text: 'SWOT'),
              Tab(text: 'PEST'),
              Tab(text: '五力'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverview(),
            _buildSWOT(),
            _buildPEST(),
            _buildFiveForces(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('市场概况', style: Theme.of(context).textTheme.titleLarge),
                const Divider(),
                ListTile(title: const Text('企业总数'), trailing: Text('${data.totalCompanies}家')),
                ListTile(title: const Text('平均注册资本'), trailing: Text(data.avgCapital)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('头部企业', style: Theme.of(context).textTheme.titleLarge),
        ...data.companies.map((c) => Card(
          child: ListTile(
            title: Text(c.name),
            subtitle: Text('${c.legalPerson} | ${c.capital}'),
            trailing: Chip(label: Text('${c.matchScore}%')),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildSWOT() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard('优势 S', Colors.green, ['市场规模大', '技术创新活跃', '政策支持']),
        _buildCard('劣势 W', Colors.orange, ['竞争激烈', '成本波动', '投入高']),
        _buildCard('机会 O', Colors.blue, ['政策利好', '出口增长', '技术突破']),
        _buildCard('威胁 T', Colors.red, ['贸易摩擦', '技术变革', '新进入者']),
      ],
    );
  }

  Widget _buildPEST() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard('政治 P', Colors.red, ['政策大力支持', '双碳目标推动']),
        _buildCard('经济 E', Colors.orange, ['市场扩大', '投融资活跃']),
        _buildCard('社会 S', Colors.green, ['接受度提高', '环保意识']),
        _buildCard('技术 T', Colors.blue, ['技术迭代', '智能化提升']),
      ],
    );
  }

  Widget _buildFiveForces() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildForce('供应商议价能力', 6, Colors.orange),
        _buildForce('买方议价能力', 7, Colors.orange),
        _buildForce('新进入者威胁', 8, Colors.red),
        _buildForce('替代品威胁', 5, Colors.yellow),
        _buildForce('同业竞争', 9, Colors.red),
      ],
    );
  }

  Widget _buildCard(String title, Color color, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        children: items.map((i) => ListTile(title: Text('• $i'))).toList(),
      ),
    );
  }

  Widget _buildForce(String title, int score, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: score / 10, color: color),
            Text('强度: $score/10'),
          ],
        ),
      ),
    );
  }
}
