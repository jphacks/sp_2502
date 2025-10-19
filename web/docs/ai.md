## About Open AI API

[taskne_task_split](https://platform.openai.com/chat/edit?prompt=pmpt_68f3462864e88197ad31ef496473ac100d80906a9dfbbb21&version=1
)

### Input

#### Variables

```txt
task: [分割したいタスク名(ノード名)を入れる string型]
graph: [分割するノードが所属しているグループ(json形式) string型]
```

#### prompt

なし

#### Expected Output

```json
{
  "first_half": "[前半ノード 15文字以内]",
  "second_half": "[後半ノード 15文字以内]"
}
```

### Example

#### TypeScript

```ts
import OpenAI from "openai";


const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const response = await openai.responses.create({
    prompt: {
        "id": "pmpt_68f3462864e88197ad31ef496473ac100",
        "version": "1",
        "variables": {
            "task": "example task",
            "graph": "example graph"
        }
    }
});
```
