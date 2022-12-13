import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const Scaffold(
          body: SafeArea(
              child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CustomTextField(),
          )),
        ));
  }
}

class CustomTextField extends StatefulWidget {
  const CustomTextField({Key? key}) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _textEditingController;
  late bool _isEmpty;
  late bool _isLoading;
  final List<String> _hintsToShow = [];
  List apiRes = [];

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _isEmpty = true;
    _isLoading = false;
    _textEditingController.addListener(() {
      if (_textEditingController.text.isNotEmpty) {
        setState(() {
          _isEmpty = false;
        });
      } else if (_textEditingController.text.isEmpty) {
        setState(() {
          _isEmpty = true;
        });
      }
    });
  }

  void _showHint(String input) {
    List<String> _hintText = [
      'Lahore, Punjab',
      'Karachi Sindh',
      'Islamabad Capital',
      'Jehlum Tehsil',
      'Gujrat Distt',
    ];
    if (input.isEmpty) {
      setState(() {
        _hintsToShow.clear();
      });
    } else {
      for (var text in _hintText) {
        if (text.contains(input)) {
          if (_hintsToShow.contains(text)) {
            break;
          } else {
            _hintsToShow.add(text);
          }
        }
        setState(() {});
      }
    }
  }

  void updateLoader() {
    setState(() {
      _isLoading = !_isLoading;
    });
  }

  Future<dynamic> getData() async {
    updateLoader();
    final response = await http.get(Uri.parse(
        'https://dailymed.nlm.nih.gov/dailymed/services/v2/spls.xml'));
    updateLoader();
    if (response.statusCode == 200) {
      final myTransformer = Xml2Json();
      myTransformer.parse(response.body);
      var json = myTransformer.toGData();
      final Map res = jsonDecode(json);
      setState(() {
        apiRes = res['spls']['spl'];
      });
    } else {
      throw Exception('Failed to load album');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode focusScope = FocusScopeNode();
        if (!focusScope.hasPrimaryFocus) {
          focusScope.unfocus();
        }
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  style: const TextStyle(color: Colors.black),
                  controller: _textEditingController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: !_isEmpty
                        ? InkWell(
                            onTap: () {
                              setState(() {
                                _textEditingController.clear();
                              });
                            },
                            child: const Icon(Icons.clear_outlined))
                        : null,
                    hintText: 'Search',
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                  ),
                  onChanged: (String currentText) {
                    _showHint(currentText);
                  },
                  onSubmitted: (text) {
                    getData();
                    _hintsToShow.clear();
                  },
                  autofillHints: _hintsToShow,
                ),
                Flexible(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _isEmpty ? 0 : _hintsToShow.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 50.0, bottom: 6),
                          child: InkWell(
                            onTap: () {
                              _textEditingController.value =
                                  _textEditingController.value
                                      .copyWith(text: _hintsToShow[index]);
                              _textEditingController.selection =
                                  TextSelection.collapsed(
                                      offset:
                                          _textEditingController.text.length);
                              _hintsToShow.removeAt(index);
                            },
                            child: Text(
                              _hintsToShow[index],
                            ),
                          ),
                        );
                      }),
                )
              ],
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Expanded(
              child: _isLoading
                  ? const CircularProgressIndicator.adaptive()
                  : ListView.builder(
                      itemCount: apiRes.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            '${apiRes[index]['title']['\$t']}',
                          ),
                          subtitle: Text(
                            '${apiRes[index]['published_date']['\$t']}',
                          ),
                        );
                      }))
        ],
      ),
    );
  }
}
