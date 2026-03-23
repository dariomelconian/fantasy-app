import os
from anthropic import Anthropic
from dotenv import load_dotenv

load_dotenv()

api_key = os.getenv("ANTHROPIC_API_KEY")

if not api_key:
    raise ValueError("ANTHROPIC_API_KEY not found in .env file")


client = Anthropic(api_key=api_key)


def get_response(conversation_history):
    response = client.messages.create(
        model="claude-3-7-sonnet-latest",
        max_tokens=500,
        messages=conversation_history,
    )
    return response.content[0].text


def main():
    print("Claude CLI Assistant started. Type 'quit' to exit.\n")

    conversation_history = []

    while True:
        user_input = input("You: ").strip()

        if user_input.lower() in {"quit", "exit"}:
            print("Goodbye.")
            break

        conversation_history.append(
            {"role": "user", "content": user_input}
        )

        try:
            reply = get_response(conversation_history)
            print(f"\nClaude: {reply}\n")

            conversation_history.append(
                {"role": "assistant", "content": reply}
            )
        except Exception as e:
            print(f"\nError: {e}\n")


if __name__ == "__main__":
    main()