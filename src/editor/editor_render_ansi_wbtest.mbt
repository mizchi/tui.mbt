///|
test "render ansi snapshot" {
  let text =
    #|type User = {
    #|  id: number
    #|  name: string
    #|}
    #|
    #|const user: User = { id: 1, name: "mizchi" }
    #|
    #|function greet(name: string): string {
    #|  return `Hello, ${name}`
    #|}
    #|
    #|console.log(greet(user.name))
    #|
  let height = 12
  let width = 60
  let state = EditorState::new(text, height - 2)
  let lines = render_lines_ansi(state, width, height)
  inspect(lines, content="")
}
