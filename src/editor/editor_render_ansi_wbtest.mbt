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
  inspect(lines, content=(
    #|["\u{1b}[1m\u{1b}[38;5;249m\u{1b}[48;5;16m editor \u{1b}[0m", "\u{1b}[38;5;243m 1 \u{1b}[0m\u{1b}[38;5;233m\u{1b}[48;5;253mt\u{1b}[0m\u{1b}[38;5;177mype\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;210mUser\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;116m=\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;188m{\u{1b}[0m", "\u{1b}[38;5;243m 2 \u{1b}[0m\u{1b}[38;5;188m  \u{1b}[0m\u{1b}[38;5;210mid\u{1b}[0m\u{1b}[38;5;188m:\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;222mnumber\u{1b}[0m", "\u{1b}[38;5;243m 3 \u{1b}[0m\u{1b}[38;5;188m  \u{1b}[0m\u{1b}[38;5;210mname\u{1b}[0m\u{1b}[38;5;188m:\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;222mstring\u{1b}[0m", "\u{1b}[38;5;243m 4 \u{1b}[0m\u{1b}[38;5;188m}\u{1b}[0m", "\u{1b}[38;5;243m 5 \u{1b}[0m ", "\u{1b}[38;5;243m 6 \u{1b}[0m\u{1b}[38;5;177mconst\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;210muser\u{1b}[0m\u{1b}[38;5;188m:\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;210mUser\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;116m=\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;188m{\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;210mid\u{1b}[0m\u{1b}[38;5;188m:\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;180m1\u{1b}[0m\u{1b}[38;5;188m,\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;210mname\u{1b}[0m\u{1b}[38;5;188m:\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;150m\"mizchi\"\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;188m}\u{1b}[0m", "\u{1b}[38;5;243m 7 \u{1b}[0m ", "\u{1b}[38;5;243m 8 \u{1b}[0m\u{1b}[38;5;177mfunction\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;210mgreet\u{1b}[0m\u{1b}[38;5;188m(\u{1b}[0m\u{1b}[38;5;210mname\u{1b}[0m\u{1b}[38;5;188m:\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;222mstring\u{1b}[0m\u{1b}[38;5;188m)\u{1b}[0m\u{1b}[38;5;188m:\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;222mstring\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;188m{\u{1b}[0m", "\u{1b}[38;5;243m 9 \u{1b}[0m\u{1b}[38;5;188m  \u{1b}[0m\u{1b}[38;5;177mreturn\u{1b}[0m\u{1b}[38;5;188m \u{1b}[0m\u{1b}[38;5;150m`Hello, ${\u{1b}[0m\u{1b}[38;5;210mname\u{1b}[0m\u{1b}[38;5;150m}`\u{1b}[0m", "\u{1b}[38;5;243m10 \u{1b}[0m\u{1b}[38;5;188m}\u{1b}[0m", "\u{1b}[38;5;247m\u{1b}[48;5;16m Ln 1, Col 1\u{1b}[0m"]

  ))
}
