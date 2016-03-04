//
//  PlayListVC.m
//  DemoForPili
//
//  Created by   何舒 on 16/3/3.
//  Copyright © 2016年 Aaron. All rights reserved.
//

#import "PlayListVC.h"
#import "MJRefresh.h"
#import "StreamSetingVC.h"
#import "PLPlayerViewController.h"

@interface PlayListVC ()<UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) NSMutableArray * dataArray;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@end

@implementation PlayListVC


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"直播列表";
    
    UIBarButtonItem * pushStreamBtn = [[UIBarButtonItem alloc] initWithTitle:@"直播" style:UIBarButtonItemStylePlain target:self action:@selector(pushStream)];
    self.navigationItem.rightBarButtonItem = pushStreamBtn;
    
    self.dataArray = [[NSMutableArray alloc] init];
    [self setupRefresh];
}

- (void)viewWillAppear:(BOOL)animated
{
    //#warning 自动刷新(一进入程序就下拉刷新)
    [self.tableView headerBeginRefreshing];
}

- (void)pushStream
{
    StreamSetingVC * streamSetingVC = [[StreamSetingVC alloc] init];
    [self.navigationController pushViewController:streamSetingVC animated:YES];
}

/**
 *  集成刷新控件
 */
- (void)setupRefresh
{
    // 1.下拉刷新(进入刷新状态就会调用self的headerRereshing)
    [self.tableView addHeaderWithTarget:self action:@selector(headerRereshing)];
    //#warning 自动刷新(一进入程序就下拉刷新)
    [self.tableView headerBeginRefreshing];
    
    // 设置文字(也可以不设置,默认的文字在MJRefreshConst中修改)
    self.tableView.headerPullToRefreshText = @"下拉可以刷新";
    self.tableView.headerReleaseToRefreshText = @"松开马上刷新";
    self.tableView.headerRefreshingText = @"刷新中";

}

#pragma mark 下拉刷新
- (void)headerRereshing
{
    [HTTPRequestPost hTTPRequest_GetpostBody:nil andUrl:@"api/streams" andSucceed:^(NSURLSessionDataTask *task, id responseObject) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.dataArray removeAllObjects];
            [self.dataArray addObjectsFromArray:responseObject[@"streams"]];
            [self.tableView reloadData];
            [self setEndhead];
        });
    } andFailure:^(NSURLSessionDataTask *task, NSError *error) {
        [self setEndhead];
    } andISstatus:NO];
}




- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * cellIdenfier = @"cell";
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdenfier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdenfier];
    }
    NSString * streamUrlString = self.dataArray[indexPath.row];
    NSArray * array = [streamUrlString componentsSeparatedByString:@":"];
    cell.textLabel.text = array[1];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *urlString = self.dataArray[indexPath.row];
    NSArray * array = [urlString componentsSeparatedByString:@":"];
    PLPlayerViewController * plplayerVC = [[PLPlayerViewController alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"rtmp://cloudvdn.pili.cloudvdn.publish:1835/%@",array[1]]]];
    [self.navigationController pushViewController:plplayerVC animated:YES];
    
}

-(void)setEndhead;
{
    [self.tableView headerEndRefreshing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
