import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NewsListPage(),
    );
  }
}

class NewsListPage extends StatefulWidget {
  @override
  _NewsListPageState createState() => _NewsListPageState();
}

class _NewsListPageState extends State<NewsListPage> {
  String _selectedCategory = 'All';
  TextEditingController _searchController = TextEditingController();
  late Future<List<dynamic>> _newsListFuture;
  late String _formattedDate;

  @override
  void initState() {
    super.initState();
    _formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    _newsListFuture = fetchNews();
  }

  Future<List<dynamic>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse(
          'https://newsapi.org/v2/everything?q=tesla&from=2024-02-22&sortBy=publishedAt&apiKey=20dfce9febf84941bc0d78df37d74c84'));
      if (response.statusCode == 200) {
        final articles = json.decode(response.body)['articles'];
        return articles;
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      throw Exception('Failed to load news');
    }
  }

  List<dynamic> filterNewsByCategory(List<dynamic> articles) {
    if (_selectedCategory == 'All') {
      return articles;
    } else {
      return articles
          .where((article) => article['category'] == _selectedCategory)
          .toList();
    }
  }

  List<dynamic> filterNewsBySearchTerm(
      List<dynamic> articles, String searchTerm) {
    if (searchTerm.isEmpty) {
      return articles;
    } else {
      return articles.where((article) {
        final title = article['title'].toString().toLowerCase();
        return title.contains(searchTerm.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_formattedDate',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            Text(
              'Explore',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for article...',
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildCategoryButton('All'),
              buildCategoryButton('Politics'),
              buildCategoryButton('Sports'),
              buildCategoryButton('Health'),
              buildCategoryButton('Saved'),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _newsListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print('Error fetching news: ${snapshot.error}');
                  return Center(
                      child:
                          Text('Error fetching news. Please try again later.'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No news available'));
                } else {
                  final filteredArticles = filterNewsBySearchTerm(
                    filterNewsByCategory(snapshot.data!),
                    _searchController.text,
                  );
                  return ListView.builder(
                    itemCount: filteredArticles.length,
                    itemBuilder: (context, index) {
                      var article = filteredArticles[index];
                      return ListTile(
                        leading: article['urlToImage'] != null
                            ? Image.network(
                                article['urlToImage'],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : SizedBox(
                                width: 80,
                                height: 80,
                                child: Center(
                                  child: Text('No Image'),
                                ),
                              ),
                        title: Text(article['title']),
                        subtitle: Text(
                          '${article['source']['name']} • ${article['publishedAt']}',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewsDetailPage(
                                article: article,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: () {
        if (category == 'Saved') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SavedNewsPage(),
            ),
          );
        } else {
          setState(() {
            _selectedCategory = category;
          });
        }
      },
      child: Text(category),
    );
  }
}

class NewsDetailPage extends StatefulWidget {
  final Map<String, dynamic> article;

  NewsDetailPage({required this.article});

  @override
  _NewsDetailPageState createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    checkSaved();
  }

  Future<void> checkSaved() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedArticles = prefs.getStringList('savedArticles');
    if (savedArticles != null) {
      setState(() {
        isSaved = savedArticles.any((articleJson) =>
            jsonDecode(articleJson)['title'] == widget.article['title']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isSaved = !isSaved;
                if (isSaved) {
                  saveArticle(widget.article);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã lưu')),
                  );
                } else {
                  removeArticle(widget.article);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã bỏ lưu')),
                  );
                }
              });
            },
            icon: Icon(
              Icons.favorite,
              color: isSaved ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.article['urlToImage'] != null &&
                widget.article['urlToImage'] != '')
              Image.network(widget.article['urlToImage']),
            SizedBox(height: 16.0),
            Text(
              '${widget.article['source']['name']} • ${widget.article['publishedAt']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              '${widget.article['title']}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              'Content:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Text(
              '${widget.article['content'] ?? 'No content'}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveArticle(Map<String, dynamic> article) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedArticles = prefs.getStringList('savedArticles') ?? [];
    savedArticles.add(jsonEncode(article));
    await prefs.setStringList('savedArticles', savedArticles);
  }

  Future<void> removeArticle(Map<String, dynamic> article) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedArticles = prefs.getStringList('savedArticles') ?? [];
    savedArticles.removeWhere((articleJson) =>
        jsonDecode(articleJson)['title'] == widget.article['title']);
    await prefs.setStringList('savedArticles', savedArticles);
  }
}

class SavedNewsPage extends StatelessWidget {
  Future<List<dynamic>> getSavedArticles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedArticles = prefs.getStringList('savedArticles');
    if (savedArticles != null) {
      return savedArticles
          .map((articleJson) => jsonDecode(articleJson))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Các bài đã lưu'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: getSavedArticles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Không có bài báo nào đã lưu'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var article = snapshot.data![index];
                return ListTile(
                  leading: article['urlToImage'] != null &&
                          article['urlToImage'] != ''
                      ? Image.network(
                          article['urlToImage'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : SizedBox(
                          width: 80,
                          height: 80,
                          child: Center(
                            child: Text('No Image'),
                          ),
                        ),
                  title: Text(article['title']),
                  subtitle: Text(
                      '${article['source']['name']} • ${article['publishedAt']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailPage(article: article),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
