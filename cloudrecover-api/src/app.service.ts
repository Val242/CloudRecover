import { Injectable } from "@nestjs/common";

@Injectable()
export class AppService {
  getHello(): string {
    //appservice
    return "Hello World!";
  }
}
