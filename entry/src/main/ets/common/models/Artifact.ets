// common/models/Artifact.ets

// 定义一个文物类型（TypeScript 接口）
export interface Artifact {
  id: string;           // 文物唯一ID
  title: string;        // 名称
  imageUrl: string;     // 图片地址
  imageUrls?: string[];   // 新增：多图数组
  period: string;       // 年代
  type: string;         // 类型（瓷器、书画等）
  material: string;     // 材质
  description: string;  // 介绍
  museum: string;       // 收藏博物馆
  popularity?: number;   // 新增：热度值（数值越大越热门）
}

// 模拟的文物数据（Mock Data），供开发时使用
export const mockArtifacts: Artifact[] = [
  {
    id: '1',
    title: '青花缠枝莲纹瓶',
    imageUrl: 'https://example.com/qinghua1.jpg',  // 暂时用假的，后面会替换
    imageUrls: [  // 新增多图数据
      'https://example.com/qinghua1.jpg',
      'https://example.com/qinghua1_2.jpg',
      'https://example.com/qinghua1_3.jpg'
    ],
    period: '明·永乐',
    type: '瓷器',
    material: '瓷',
    description: '明代永乐年间青花瓷代表作，造型优美，纹饰流畅。',
    museum: '大英博物馆',
    popularity: 85
  },
  {
    id: '2',
    title: '唐三彩骆驼载乐俑',
    imageUrl: 'https://example.com/sancai.jpg',
    period: '唐',
    type: '陶器',
    material: '陶',
    description: '唐代三彩陶器，骆驼背上载有乐舞俑，反映丝绸之路文化。',
    museum: '大都会艺术博物馆',
    popularity: 86
  },
  {
    id: '3',
    title: '《富春山居图》局部',
    imageUrl: 'https://example.com/fuchun.jpg',
    period: '元',
    type: '书画',
    material: '纸本',
    description: '元代黄公望代表作，中国十大传世名画之一。',
    museum: '克利夫兰艺术博物馆',
    popularity: 89
  },
  {
    id: '4',
    title: '玉琮',
    imageUrl: 'https://example.com/yucong.jpg',
    period: '良渚文化',
    type: '玉器',
    material: '玉',
    description: '古代祭祀用玉器，内圆外方，象征天圆地方。',
    museum: '弗利尔美术馆',
    popularity: 90
  },
  {
    id: '5',
    title: '青铜爵',
    imageUrl: 'https://example.com/jue.jpg',
    period: '商',
    type: '青铜器',
    material: '青铜',
    description: '商代饮酒器，三足，流尾明显。',
    museum: '哈佛艺术博物馆',
    popularity: 81
  },
  // 在现有 mockArtifacts 数组末尾追加以下条目
  {
    id: '6',
    title: '唐彩绘仕女俑',
  imageUrl: 'https://example.com/tang_lady.jpg',
  imageUrls: [
    'https://example.com/tang_lady_1.jpg',
    'https://example.com/tang_lady_2.jpg'
    ],
    period: '唐',                    // 与 id:2 同朝代，测试关联实体
    type: '陶器',                    // 与 id:2 同类型，测试相关推荐
  material: '陶',
  description: '唐代彩绘陶俑，仕女形象丰满，反映了唐代以胖为美的审美风尚。',
  museum: '大英博物馆'             // 与 id:1 同博物馆，测试博物馆筛选
  },
  {
    id: '7',
    title: '元青花鬼谷子下山图罐',
  imageUrl: 'https://example.com/yuan_blue.jpg',
  period: '元',                    // 与 id:3 同朝代
  type: '瓷器',                    // 与 id:1 同类型
  material: '瓷',
  description: '元代青花瓷代表作，2005年以2.3亿元成交，创下当时中国艺术品拍卖纪录。',
  museum: '大都会艺术博物馆'        // 与 id:2 同博物馆
  },
  {
    id: '8',
    title: '商晚期青铜方彝',
  imageUrl: 'https://example.com/shang_fangyi.jpg',
  imageUrls: [
    'https://example.com/shang_fangyi_1.jpg',
    'https://example.com/shang_fangyi_2.jpg',
    'https://example.com/shang_fangyi_3.jpg',
    'https://example.com/shang_fangyi_4.jpg'
    ],
    period: '商',                    // 与 id:5 同朝代
    type: '青铜器',                  // 与 id:5 同类型
  material: '青铜',
  description: '商代晚期青铜礼器，器身饰有饕餮纹，铸造工艺精湛。',
  museum: '弗利尔美术馆'            // 与 id:4 同博物馆
  },
  {
    id: '9',
    title: '良渚文化玉璧',
  imageUrl: 'https://example.com/liangzhu_bi.jpg',
  period: '良渚文化',              // 与 id:4 同朝代
  type: '玉器',                    // 与 id:4 同类型
  material: '玉',
  description: '良渚文化大型玉璧，表面光滑，中孔对钻而成，体现了高超的制玉技术。',
  museum: '哈佛艺术博物馆'          // 与 id:5 同博物馆
  },
  {
    id: '10',
    title: '明宣德青花海水龙纹瓶',
  imageUrl: 'https://example.com/xuande_dragon.jpg',
  imageUrls: [
    'https://example.com/xuande_dragon_1.jpg',
    'https://example.com/xuande_dragon_2.jpg'
    ],
    period: '明·永乐',               // 与 id:1 同朝代，用于测试同朝代关联
    type: '瓷器',                    // 与 id:1、id:7 同类型
  material: '瓷',
  description: '明宣德年间青花瓷器，龙纹威猛生动，海水纹细腻流畅，为明代官窑精品。',
  museum: '大英博物馆'              // 与 id:1、id:6 同博物馆
  },
  {
    id: '11',
    title: '唐代金银平脱镜',
  imageUrl: 'https://example.com/tang_mirror.jpg',
  period: '唐',                    // 与 id:2、id:6 同朝代
  type: '铜镜',                    // 新类型，可测试筛选新增类型
  material: '铜',
  description: '唐代金银平脱工艺铜镜，镜背以金银薄片镶嵌成花鸟图案，极为精美。',
  museum: '克利夫兰艺术博物馆'      // 与 id:3 同博物馆
  },
  {
    id: '12',
    title: '东汉绿釉陶楼',
  imageUrl: 'https://example.com/han_tower.jpg',
  imageUrls: [
    'https://example.com/han_tower_1.jpg',
    'https://example.com/han_tower_2.jpg'
    ],
    period: '东汉',                  // 新年代，丰富年代筛选选项
    type: '陶器',                    // 与 id:2、id:6 同类型
  material: '陶',
  description: '东汉绿釉陶楼模型，反映了汉代建筑的形制特点，釉色翠绿明亮。',
  museum: '大英博物馆'              // 与 id:1、id:6、id:10 同博物馆
  }
];