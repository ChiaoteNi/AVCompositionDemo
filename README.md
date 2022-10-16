# AVCompositionDemo

本系列將分成三部分：

### PART I - AVComposition 的簡介 (9/13)
- 將介紹如果使用AVComposition，你大致需要實作＆經過什麼流程
- 主要是先有個概觀，不會說明最複雜的VideoComposition內部實做
- 範例將帶過：
  - 影片的播放
  - 對播放時間的調整
  - 串連兩個影片(但不包含VideoComposition部分)

### PART II - AVVideoComposition的實做 (10/18)
- 將會介紹如何藉由AVVideoComposition控制影片的播放，包含：
  - 影片過場間的特效
  - 同時並行播放複數個影片
- 本次部分將會涉及MetaKit的使用，還沒接觸過的朋友，建議可先參考下之前Doodle with MetalKit的Demo

### PART III - AVVideoComposition後續＆AVAudioMix (11/15)
- 將會介紹AVVideoComposition剩餘部分，包含：
  - 如何與圖片混合播放
  - 在影片播放上時覆蓋另一影片 / 圖片 / 文字
  - 如果時間足夠，將會包含AVAudioMix部分
