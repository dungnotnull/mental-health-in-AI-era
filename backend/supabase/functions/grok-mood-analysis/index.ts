// @ts-ignore
const GROK_API_KEY = Deno.env.get("GROK_API_KEY");

// @ts-ignore
Deno.serve(async (req) => {
  // Xử lý CORS để Flutter gọi được từ Web/Mobile
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { "Access-Control-Allow-Origin": "*" },
    });
  }

  try {
    const { mood_score, feeling_text } = await req.json();

    const prompt = `
      Bạn là một người anh em thân thiết (Bro). 
      Người dùng đang cảm thấy mức độ ${mood_score}/5 và chia sẻ: "${feeling_text}".
      Hãy phản hồi bằng tiếng Việt, phong cách cực kỳ ngầu, tích cực và "vibe" thanh niên.
      Trả về định dạng JSON gồm:
      - "super_power": Một siêu năng lực ảo tưởng nhưng cực hài hước dựa trên mood này.
      - "money_tip": Một lời khuyên kiếm tiền thực tế hoặc vui nhộn phù hợp với tâm trạng này.
    `;

    const response = await fetch("https://api.x.ai/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${GROK_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "grok-beta",
        messages: [
          { role: "system", content: "You are a helpful bro." },
          { role: "user", content: prompt },
        ],
        // Ép kiểu JSON trả về cho chuẩn
        response_format: { type: "json_object" },
      }),
    });

    const aiData = await response.json();
    const content = aiData.choices[0].message.content;

    return new Response(content, {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*", // Cho phép Flutter gọi API
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        super_power: "Tâm lý thép",
        money_tip:
          "Hôm nay Grok AI đang đi nhậu, bro cứ tiết kiệm tiền là đã giàu rồi!",
        error: (error as Error).message,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  }
});
