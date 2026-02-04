///|
test "kitty_command builds payload" {
  let cmd = kitty_command(["a=t", "f=100"], payload="abc")
  assert_eq(cmd, "\u001b_Ga=t,f=100;abc\u001b\\")
}

///|
test "kitty_transmit_png chunks" {
  let chunks = kitty_transmit_png(3, "abcd", chunk_size=2)
  assert_eq(chunks.length(), 2)
  assert_eq(chunks[0], "\u001b_Ga=t,f=100,i=3,m=1,q=1;ab\u001b\\")
  assert_eq(chunks[1], "\u001b_Gm=0,q=1;cd\u001b\\")
}

///|
test "kitty_place with crop" {
  let rect = CropRect::{ x: 16, y: 8, w: 24, h: 32 }
  let cmd = kitty_place(id=1, placement_id=7, crop=rect)
  assert_eq(cmd, "\u001b_Ga=p,i=1,p=7,C=1,x=16,y=8,w=24,h=32,q=1;\u001b\\")
}

///|
test "kitty_place with size" {
  let cmd = kitty_place(id=3, placement_id=9, cols=10, rows=5)
  assert_eq(cmd, "\u001b_Ga=p,i=3,p=9,C=1,c=10,r=5,q=1;\u001b\\")
}
