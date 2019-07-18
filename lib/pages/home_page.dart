import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:flutter_trip/dao/home_dao.dart';
import 'package:flutter_trip/model/common_model.dart';
import 'package:flutter_trip/model/grid_nav_model.dart';
import 'package:flutter_trip/model/home_model.dart';
import 'package:flutter_trip/model/sales_box_model.dart';
import 'package:flutter_trip/widget/grid_nav.dart';
import 'package:flutter_trip/widget/loading_container.dart';
import 'package:flutter_trip/widget/local_nav.dart';
import 'package:flutter_trip/widget/sales_box.dart';
import 'package:flutter_trip/widget/search_bar.dart';
import 'package:flutter_trip/widget/sub_nav.dart';
import 'package:flutter_trip/widget/web_view.dart';

const APPBAR_SCROLL_OFFSET = 100;
const SEARCH_BAR_DEFAULT_TEXT = '网红打卡地 景点 酒店 美食';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _appBarAlpha = 0; // 初始值为全透明
  List<CommonModel> _bannerList = [];
  List<CommonModel> _localNavList = [];
  GridNavModel _gridNavModel;
  List<CommonModel> _subNavList = [];
  SalesBoxModel _salesBox;
  bool _loading = true;

  @override
  void initState() {
    // 重写initState()方法
    super.initState();
    _handleRefresh();
  }

  _onScroll(offset) {
    double alpha = offset / APPBAR_SCROLL_OFFSET;
    if (alpha < 0) {
      alpha = 0;
    } else if (alpha > 1) {
      alpha = 1;
    }
    setState(() {
      _appBarAlpha = alpha;
    });
    print(_appBarAlpha);
  }

  Future<Null> _handleRefresh() async {
    try {
      HomeModel model = await HomeDao.fetch();
      setState(() {
        _bannerList = model.bannerList;
        _localNavList = model.localNavList;
        _gridNavModel = model.gridNav;
        _subNavList = model.subNavList;
        _salesBox = model.salesBox;
        _loading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        _loading = false;
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff2f2f2),
      body: LoadingContainer(
        isLoading: _loading,
        child: Stack(
          // 使用此组件达到相对布局的效果
          children: <Widget>[
            MediaQuery.removePadding(
              // 移除上边距达到沉浸式状态栏的效果
              removeTop: true,
              context: context,
              child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: NotificationListener(
                    // 滑动监听
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification &&
                          scrollNotification.depth == 0) {
                        // 不考虑子元素的滑动
                        _onScroll(scrollNotification.metrics.pixels);
                      }
                    },
                    child: _listView,
                  )),
            ),
            Column(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      // AppBar渐变遮罩背景
                      colors: [Color(0x66000000), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(
                          (_appBarAlpha * 255).toInt(), 255, 255, 255),
                    ),
                    child: SearchBar(
                      searchBarType: _appBarAlpha > 0.2
                          ? SearchBarType.homeLight
                          : SearchBarType.home,
                      inputBoxClick: _jumpToSearch,
                      speakClick: _jumpToSpeak,
                      defaultText: SEARCH_BAR_DEFAULT_TEXT,
                      leftButtonClick: () {},
                    ),
                  ),
                ),
                Container(
                  height: _appBarAlpha > 0.2 ? 0.5 : 0,
                  decoration: BoxDecoration(boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 0.5)
                  ]),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  _clickBanner(BuildContext context, CommonModel model) {
    Navigator.push(
        // 打开自定义WebView页面
        context,
        MaterialPageRoute(
            builder: (context) => WebView(
                  url: model.url,
                  statusBarColor: model.statusBarColor,
                  hideAppBar: model.hideAppBar,
                )));
  }

  _jumpToSearch() {}

  _jumpToSpeak() {}

  Widget get _listView {
    return ListView(
      children: <Widget>[
        Container(
          height: 160,
          child: Swiper(
            // 第三方组件，需在pubspec文件中引入并在此类头导包
            itemCount: _bannerList.length, // 轮播图个数
            autoplay: true, // 轮播图自动播放
            itemBuilder: (BuildContext context, int index) {
              return Image.network(
                _bannerList[index].icon,
                fit: BoxFit.fill, // 填充方式
              );
            },
            pagination: SwiperPagination(),
            onTap: (index) => _clickBanner(context, _bannerList[index]),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(7, 4, 7, 4),
          child: LocalNav(
            localNavList: _localNavList,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(7, 0, 7, 4),
          child: GridNav(
            gridNavModel: _gridNavModel,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(7, 0, 7, 4),
          child: SubNav(
            subNavList: _subNavList,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(7, 0, 7, 4),
          child: SalesBox(
            salesBox: _salesBox,
          ),
        ),
      ],
    );
  }
}
